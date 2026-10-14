-- Row Level Security — ADR-010
-- Prevents cross-user data access even under secondary injection vectors

ALTER TABLE saved_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrichment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

-- saved_contacts: users see only their own or their team's contacts
CREATE POLICY saved_contacts_isolation ON saved_contacts
  USING (
    user_id = current_setting('app.current_user_id', true)::uuid
    OR team_id IN (
      SELECT team_id FROM team_members
      WHERE user_id = current_setting('app.current_user_id', true)::uuid
        AND accepted_at IS NOT NULL
    )
  );

-- enrichment_events: users see only their own events
CREATE POLICY enrichment_events_isolation ON enrichment_events
  USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- consent_records: users see only their own records
CREATE POLICY consent_records_isolation ON consent_records
  USING (user_id = current_setting('app.current_user_id', true)::uuid);

-- Prevent DELETE on consent_records (immutable log — ADR-003)
CREATE RULE consent_records_no_delete AS ON DELETE TO consent_records DO INSTEAD NOTHING;
CREATE RULE consent_records_no_update AS ON UPDATE TO consent_records
  DO INSTEAD
  INSERT INTO consent_records (
    user_id, consent_enrichment, consent_collection, consent_intent,
    ip_address, user_agent, tos_version, revoked_at, revocation_reason
  ) VALUES (
    OLD.user_id, NEW.consent_enrichment, NEW.consent_collection, NEW.consent_intent,
    NEW.ip_address, NEW.user_agent, NEW.tos_version, NEW.revoked_at, NEW.revocation_reason
  );

-- Index for RLS performance
CREATE INDEX IF NOT EXISTS idx_saved_contacts_user ON saved_contacts (user_id);
CREATE INDEX IF NOT EXISTS idx_saved_contacts_team ON saved_contacts (team_id);
CREATE INDEX IF NOT EXISTS idx_enrichment_events_user ON enrichment_events (user_id);
CREATE INDEX IF NOT EXISTS idx_consent_records_user ON consent_records (user_id);
