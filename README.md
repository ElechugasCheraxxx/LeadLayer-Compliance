# LeadLayer Compliance

**Security & data-protection engineering reference for B2B SaaS handling personal data under Peruvian law (Ley 29733).**

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791.svg?)](#)
[![Node](https://img.shields.io/badge/Node-20%2B-5FA04E.svg?)](#)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

> Extracted from a production contact-enrichment SaaS: the database migrations, supply-chain
> tooling, CI gates and compliance procedures that enforce data-protection invariants **at the
> database level** rather than in application code.

---

## Why this exists

Most GDPR/Ley 29733 compliance is enforced in application code. That fails the moment someone
adds a raw SQL query, a new service, or an admin script.

Everything here moves enforcement **down the stack** — into `CREATE RULE`s, triggers, partial
indexes and CI gates — so the invariants hold regardless of what the application does.

---

## 11 security audits

The full findings are in [`docs/AUDIT_FINDINGS.md`](docs/AUDIT_FINDINGS.md).

| # | Audit | Status | Where |
|---|---|---|---|
| 1 | **Fail Stop** | ✅ | Circuit breaker; `checkOrAbort()` halts enrichment on any consent-check failure |
| 2 | **Non Viable** | ✅ | Geo-blocking; dead paths rejected at the edge |
| 3 | **Zero Trust** | ✅ | Per-request consent verification; no implicit trust |
| 4 | **Zero Tolerance** | ✅ | Input sanitization, billing integrity |
| 5 | **Kill Switch** | ✅ | Admin-triggered global halt |
| 6 | **Secure Architecture** | ✅ | Hardened containers, security headers |
| 7 | **Red Team / Offensive** | ✅ | SSRF guard, sanitization, red-team test suite |
| 8 | **Supply Chain** | ✅ | `supply-chain-audit.mjs`, Dependabot, `.npmrc` pinning |
| 9 | **Runtime Exploitability** | ✅ | Graceful shutdown, generic error surface, no internals leak |
| 10 | **Formal Verification** | ✅ | Pre/postconditions + 14 property-based tests |
| 11 | **Side-Channel** | ✅ | Constant-time crypto, token handling |

---

## Enforcement at the database level

### Immutable consent log — `db/migrations/007_rls.sql`, `010_security_hardening.sql`

Under Peruvian law a consent record may be **revoked, never edited or deleted**. That is
enforced with Postgres rules, not application code:

```sql
-- postcondition: no row is deleted, ever
CREATE RULE no_delete_consent AS ON DELETE TO consent_records DO INSTEAD NOTHING;

-- revocation is modelled as an append-only transition, not an UPDATE
CREATE RULE no_update_consent AS ON UPDATE TO consent_records
  DO INSTEAD INSERT INTO consent_records (user_id, consent_enrichment, revoked_at, ...)
  VALUES (OLD.user_id, NEW.consent_enrichment, NEW.revoked_at, ...);
```

### Row Level Security — `db/migrations/007_rls.sql`

Isolation holds even under SQL injection, because RLS applies to the session, not the query:

```sql
ALTER TABLE saved_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY saved_contacts_isolation ON saved_contacts
  USING (
    user_id = current_setting('app.current_user_id', true)::uuid
    OR team_id IN (
      SELECT team_id FROM team_members
      WHERE user_id = current_setting('app.current_user_id', true)::uuid
        AND accepted_at IS NOT NULL
    )
  );
```

### Timing-attack resistance — `db/migrations/010_security_hardening.sql`

Suppression checks are on the hot path. Without indexes, checking "is this person suppressed"
is O(n) — and the response time leaks whether a given identifier exists:

```sql
-- Without this, suppression check is O(n) — exploitable via bulk-query timing attacks
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_suppression_lookup
  ON suppression_list (identifier_type, lower(identifier_value))
  WHERE verified_at IS NOT NULL;
```

The `WHERE` clause makes it a partial index — suppressed-but-unverified entries stay out of the
hot path entirely.

### Suppression propagation — trigger, not application code

```sql
-- profiles.suppressed must stay consistent with suppression_list
CREATE OR REPLACE FUNCTION sync_profile_suppression() RETURNS TRIGGER ...
```

---

## Preconditions & postconditions

Audit 10 applies Hoare-logic contracts to the enrichment and consent paths. Every invariant is
machine-checked in CI:

| Invariant | Kind |
|---|---|
| At least one query param required | precondition |
| Email format valid if present | precondition |
| `suppressed=true ⇒ found=false` | **postcondition** |
| `Confidence ∈ [0,1]` when found | postcondition |
| Consent records immutable | DB-level rule |
| Suppression propagates to profiles | DB trigger |

Enforcement happens *before* the function executes (preconditions) and *after* it returns
(postconditions), throwing `FailStopError` on violation.

---

## Supply-chain integrity

`scripts/supply-chain-audit.mjs` parses `pnpm-lock.yaml` and fails the build on:

1. Packages resolved from **git refs** instead of a registry
2. Packages with **no integrity hash**
3. Packages from a **non-npmjs registry**

Wired into CI via [`.github/workflows/supply-chain.yml`](.github/workflows/supply-chain.yml),
alongside a Dependabot config and npm registry pinning. `scripts/sri-manifest.ts` generates
Subresource Integrity hashes for extension assets.

---

## Peruvian data-protection compliance

[`scripts/register-rnpdp.md`](scripts/register-rnpdp.md) is the operational procedure for
registration before operating — **Art. 27, Ley 29733**, before the Ministerio de Justicia
y Derechos Humanos (MINJUSDH).

It covers the three-layer model:

| Layer | Implementation |
|---|---|
| **Consent** | Granular opt-in stored in `consent_records`; immutable audit trail |
| **Traceability** | Append-only consent log with IP, user-agent, ToS version |
| **Processor model** | Suppression list checked on **every** enrichment call |

Plus transfer disclosure (Supabase/Supabase-hosted services, Railway) and retention periods.

Related documents in [`docs/`](docs/): privacy policy, DPA template, architecture notes,
API reference.

---

## Layout

```
db/migrations/
  003_consent.sql               consent model + audit trail
  004_suppression.sql           processor suppression list
  007_rls.sql                   row level security + immutable consent
  010_security_hardening.sql    timing-safe indexes, triggers, rules

scripts/
  supply-chain-audit.mjs        lockfile integrity verifier
  sri-manifest.ts               Subresource Integrity generation
  register-rnpdp.md             Ley 29733 registration procedure
  migrate.ts · seed-db.ts       DB tooling
  backup.sh · health-check.sh · smoke-test.sh

.github/workflows/
  ci.yml                        build + test + property-based invariants
  security-scan.yml             SAST / dependency scanning
  supply-chain.yml              lockfile integrity gate

docs/
  AUDIT_FINDINGS.md             11 audits, findings and mitigations
  security-architecture-review.md
  architecture.md · api-reference.md
  privacy-policy.md · data-processing-agreement.md
```

---

## Design principles

| Principle | Meaning |
|---|---|
| **Fail Stop** | Halt rather than continue in an undefined state |
| **Zero Trust** | Verify on every request; no implicit trust |
| **Zero Tolerance** | No partial failure of a security control |
| **Non Viable** | Reject paths that cannot succeed |
| **Contract-first** | Specify invariants, then enforce them mechanically |

---

## License

GPL-3.0 — see [`LICENSE`](LICENSE).


---

<div align="center">

**José Miguel Tirado Quiroz** · Security & Infrastructure Engineer · Lima, Perú

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/jose-miguel-tirado-quiroz)
[![GitHub](https://img.shields.io/badge/GitHub-ElechugasCheraxxx-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/ElechugasCheraxxx)

</div>
