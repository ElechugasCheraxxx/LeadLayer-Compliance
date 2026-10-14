-- Audit 9 (Runtime): indexes critical for suppression performance
-- Without these, suppression check is O(n) — exploitable via bulk-query timing attacks

-- suppression hot path
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppression_lookup
  ON suppression_list (identifier_type, lower(identifier_value))
  WHERE verified_at IS NOT NULL;

-- consent audit hot path
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_consent_user_latest
  ON consent_records (user_id, granted_at DESC);

-- API key verification hot path
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_keys_active
  ON api_keys (key_hash)
  WHERE revoked_at IS NULL;

-- Audit 10 (Formal): enforce immutability invariant on consent_records at DB level
-- postcondition: no row is deleted, ever
CREATE RULE no_delete_consent AS ON DELETE TO consent_records DO INSTEAD NOTHING;
CREATE RULE no_update_consent AS ON UPDATE TO consent_records DO INSTEAD NOTHING;

-- Audit 4 (Zero Tolerance): enforce suppression pre-check at DB level
-- profiles.suppressed must stay consistent with suppression_list
CREATE OR REPLACE FUNCTION sync_profile_suppression() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.verified_at IS NOT NULL THEN
    UPDATE profiles SET suppressed = true
    WHERE (email = NEW.identifier_value AND NEW.identifier_type = 'email')
       OR (source_url = NEW.identifier_value AND NEW.identifier_type = 'linkedin_url');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_suppress_profile ON suppression_list;
CREATE TRIGGER trg_suppress_profile
  AFTER INSERT OR UPDATE ON suppression_list
  FOR EACH ROW EXECUTE FUNCTION sync_profile_suppression();

-- Audit 6 (Secure Arch): row-level security — users can only read own data
ALTER TABLE saved_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY contacts_isolation ON saved_contacts
  USING (user_id = current_setting('app.current_user_id', true)::uuid);

ALTER TABLE enrichment_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY events_isolation ON enrichment_events
  USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- Audit 9 (Runtime): prevent VACUUM from blocking during heavy enrichment writes
ALTER TABLE profiles SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE enrichment_events SET (autovacuum_vacuum_scale_factor = 0.02);
