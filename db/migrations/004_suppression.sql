CREATE TABLE IF NOT EXISTS suppression_list (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier_type  TEXT NOT NULL CHECK (identifier_type IN ('email','linkedin_url','name_company')),
  identifier_value TEXT NOT NULL,
  requested_at     TIMESTAMPTZ DEFAULT now(),
  request_ip       INET,
  verified_at      TIMESTAMPTZ,
  notes            TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_suppression_unique
  ON suppression_list (identifier_type, lower(identifier_value));
