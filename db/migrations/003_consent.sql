CREATE TABLE IF NOT EXISTS consent_records (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES users(id) ON DELETE CASCADE,
  consent_enrichment  BOOLEAN NOT NULL,
  consent_collection  BOOLEAN NOT NULL,
  consent_intent      BOOLEAN NOT NULL,
  granted_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address          INET,
  user_agent          TEXT,
  tos_version         TEXT NOT NULL,
  revoked_at          TIMESTAMPTZ,
  revocation_reason   TEXT
);

CREATE INDEX IF NOT EXISTS idx_consent_user ON consent_records (user_id, granted_at DESC);
