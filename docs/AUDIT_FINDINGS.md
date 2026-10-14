# LeadLayer Security Audit Findings
## Commit: security/authority-audits-v1

---

### Summary

| # | Audit | Status | Key Files |
|---|---|---|---|
| 1 | Fail Stop | ✅ Implemented | `failStop/index.ts`, `middleware/failStop.ts` |
| 2 | Non Viable | ✅ Implemented | `middleware/geoBlock.ts`, `docs/security-architecture-review.md` |
| 3 | Zero Trust | ✅ Implemented | `middleware/zeroTrust.ts`, `routes/consent/index.ts` |
| 4 | Zero Tolerance | ✅ Implemented | `utils/sanitize.ts`, `routes/billing/index.ts` |
| 5 | Kill Switch | ✅ Implemented | `killSwitch/index.ts`, `middleware/killSwitch.ts`, `routes/admin/index.ts` |
| 6 | Secure Architecture | ✅ Implemented | `docker-compose.yml`, `Dockerfile`, `plugins/secureHeaders.ts`, `docs/security-architecture-review.md` |
| 7 | Red Team / Offensive | ✅ Implemented | `test/redteam.test.ts`, `middleware/ssrfGuard.ts`, `utils/sanitize.ts` |
| 8 | Supply Chain | ✅ Implemented | `.npmrc`, `workflows/supply-chain.yml`, `scripts/supply-chain-audit.mjs`, `.github/dependabot.yml` |
| 9 | Runtime Exploitability | ✅ Implemented | `db/postgres.ts`, `db/redis.ts`, `docker-compose.yml`, `utils/shutdown.ts`, `utils/logger.ts` |
| 10 | Siemens Formal Verification | ✅ Implemented | `contracts/index.ts`, `test/invariants.test.ts`, `migrations/008_security_hardening.sql` |
| 11 | Hardware / Side-Channel | ✅ Implemented | `utils/crypto.ts`, `utils/tokens.ts`, `test/crypto.test.ts` |

---

### Audit 1 — Fail Stop

**Principle:** A system must halt rather than continue in an unsafe or undefined state.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| External provider failures could cascade | `services/enrichment/index.ts` | CircuitBreaker wraps Hunter + Clearbit; opens after 5 failures |
| Suppression check error → data exposure | `services/consent/suppression.ts` | `checkOrAbort()` throws `FailStopError` on any check failure — enrichment aborted |
| Unhandled errors could reveal internals | `middleware/failStop.ts` | Global error handler catches all; 5xx returns generic message only |
| Invariant violations silently ignored | `packages/core/src/failStop/index.ts` | `assert()` primitive throws `FailStopError` on violation |

---

### Audit 2 — Non Viable

**Principle:** Identify conditions under which the product becomes legally or operationally non-viable and hard-block them.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| GDPR enforcement in EU = existential fine | `middleware/geoBlock.ts` | 30 EU/UK country codes blocked at request layer, HTTP 451 |
| DL 1700 Art. 12-A: bulk DB sale illegal | `routes/b2b-api/index.ts` | No bulk dump endpoint; `/data/bulk` hard-capped at 1,000 individual queries |
| TOR exit node: data collection non-viable | `middleware/geoBlock.ts` | Cloudflare `cf-connecting-o2o` header → 403 |
| Intent data without consent: regulatory non-viable | `background/index.ts` | Consent gate is local + synchronous; no intent event sent without `consent_intent=true` |
| Missing RNPDP registration | `infrastructure/scripts/register-rnpdp.md` | Checklist and instructions for MINJUSDH registration |

---

### Audit 3 — Zero Trust

**Principle:** Never trust; always verify. No implicit trust based on network location, prior authentication, or session state.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| Internal services trusted by default | `docker-compose.yml` | DB/Redis on `backend` internal network; no direct external exposure |
| JWT sub not re-validated on each request | `middleware/zeroTrust.ts` | JWT verified on every request via `preHandler` hook |
| API key lookup vulnerable to timing oracle | `middleware/zeroTrust.ts` | Iterates all rows in constant time; `constantTimeDelay()` applied regardless |
| Enrichment consent not checked per-call | `routes/enrich/handlers.ts` | `hasEnrichmentConsent()` checked before every enrichment |
| Intent consent assumed from session | `background/index.ts` | Consent re-read from `chrome.storage` on every navigation event |

---

### Audit 4 — Zero Tolerance

**Principle:** Certain classes of failure have zero acceptable occurrence rate.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| Stripe signature bypass | `routes/billing/index.ts` | `stripe.webhooks.constructEvent()` always verified; rejection on failure |
| Arbitrary price ID injection | `routes/billing/index.ts` | Price IDs whitelisted — only known IDs accepted |
| Stack traces in 500 responses | `middleware/failStop.ts` | Error handler strips internals; only safe message returned |
| SQL injection via string concat | `utils/sanitize.ts` | Zod schemas + parameterized queries everywhere; no string interpolation in SQL |
| Webhook without raw body | `routes/billing/index.ts` | `rawBody: true` plugin config; rejects parsed body for webhook endpoint |

---

### Audit 5 — Kill Switch

**Principle:** Any feature generating risk or revenue must be individually disableable in <1 second without a deployment.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| No emergency stop for enrichment | `middleware/killSwitch.ts` | `requireFeature('enrichment')` preHandler on all enrich routes |
| No emergency stop for intent data | `routes/intent/index.ts` | `requireFeature('intent')` preHandler |
| No emergency stop for B2B API | `routes/b2b-api/index.ts` | `requireFeature('b2b-api')` + `requireFeature('bulk-api')` |
| Kill switch state unknown to ops | `routes/health/index.ts` | `/ready` endpoint exposes all flag states |
| Kill switch requires deployment to toggle | `routes/admin/index.ts` | Redis-backed, togglable via `POST /admin/kill-switch` with ADMIN_SECRET |

---

### Audit 6 — Secure Architecture Review

**Principle:** Security is a structural property, not a layer added after the fact.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| No defense-in-depth on headers | `plugins/secureHeaders.ts` | Full suite: HSTS, CSP, COEP, CORP, COOP, nosniff, no-referrer |
| CORS wildcard risk | `plugins/cors.ts` | Explicit allowlist from env; no `*`; credentials=true |
| Container runs as root | `apps/api/Dockerfile` | `USER nonroot`, distroless base, `no-new-privileges:true` in compose |
| DB/Redis directly exposed | `docker-compose.yml` | `internal: true` network; only API has egress |
| User data not isolated at DB level | `migrations/008_security_hardening.sql` | RLS on `saved_contacts` + `enrichment_events` |
| No architectural decision record | `docs/security-architecture-review.md` | Full ADR with threat model, residual risk table |

---

### Audit 7 — Red Team / Adversarial / Offensive Black Hat

**Principle:** Actively attempt to break the system before attackers do.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| SQL injection via email/URL params | `test/redteam.test.ts` | 5 payload variants tested; Zod + parameterized queries block all |
| SSRF via linkedinUrl field | `middleware/ssrfGuard.ts` | Allowlist of 5 hosts; private range block; redirect=error |
| alg:none JWT bypass | `test/redteam.test.ts` | Fastify JWT rejects alg:none |
| Prototype pollution in request body | `utils/sanitize.ts` | `sanitizeObject()` strips `__proto__`, `constructor`, `prototype` |
| Bulk API as DB dump vector | `routes/b2b-api/index.ts` | Hard cap 1,000; each query suppression-checked individually |
| Information disclosure in 500s | `test/redteam.test.ts` | Verified: no stack traces, paths, or module names in responses |
| Server header fingerprinting | `plugins/secureHeaders.ts` | `server: 'leadlayer'` — no runtime version |

---

### Audit 8 — Supply Chain Security

**Principle:** The build and dependency pipeline is an attack surface.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| Packages could be pulled from git refs | `scripts/supply-chain-audit.mjs` | Script flags any git:// resolution in lockfile |
| Packages with no integrity hash | `scripts/supply-chain-audit.mjs` | Script flags missing `integrity` fields |
| Malicious postinstall scripts | `workflows/supply-chain.yml` | CI scans for `curl`, `wget`, `bash` in postinstall hooks |
| Container image vulnerabilities | `workflows/security-scan.yml` | Trivy scan on CI; CRITICAL/HIGH fail the build |
| Lockfile drift | `workflows/supply-chain.yml` | SHA-256 of lockfile logged on every PR |
| Stale transitive dependencies | `.github/dependabot.yml` | Weekly Dependabot for npm, docker, and GitHub Actions |
| Non-standard registry | `.npmrc` | Registry pinned to `registry.npmjs.org` |

---

### Audit 9 — Runtime Exploitability Analysis

**Principle:** Reduce the exploitability of vulnerabilities that do exist.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| Long-running SQL payloads (time-based injection) | `db/postgres.ts` | `statement_timeout=10000` globally on all connections |
| Redis dangerous commands (`FLUSHALL`, `DEBUG`) | `docker-compose.yml` | Renamed to `""` in Redis config |
| Large body DoS | `apps/api/src/index.ts` | `bodyLimit: 256 * 1024` in Fastify config |
| Runaway DB connections | `db/postgres.ts` | Pool max=20, idle timeout 30s, connection timeout 5s |
| SIGTERM → data corruption | `utils/shutdown.ts` | Graceful shutdown: close server → drain DB → quit Redis, 10s timeout |
| PII in logs | `utils/logger.ts` | `redact()` strips `email`, `phone`, `full_name`, `ip_address` from all log objects |
| Container privilege escalation | `docker-compose.yml` | `no-new-privileges:true` on all services |
| Redis keyspace collisions | `db/redis.ts` | `keyPrefix` scopes all keys to `leadlayer:` namespace |

---

### Audit 10 — Siemens Formal Verification

**Principle:** Critical properties are specified as machine-checkable contracts and verified at runtime (without rewriting in Coq/Isabelle — principle applied in TypeScript).

**Invariants Specified and Enforced:**

| Invariant | Specification | Enforcement |
|---|---|---|
| At least one query param required | `enrichmentContract.pre[0]` | `enforce()` wrapper; throws `FailStopError` before fn executes |
| Email format valid if present | `enrichmentContract.pre[1]` | Regex checked in precondition |
| `suppressed=true ⇒ found=false` | `enrichmentContract.post[2]` | Postcondition checked after fn returns |
| Confidence ∈ [0, 1] when found | `enrichmentContract.post[1]` | Postcondition checked after fn returns |
| UserId non-empty string | `consentContract.pre[0]` | Precondition |
| TosVersion format YYYY-MM-DD | `consentContract.pre[1]` | Regex precondition |
| Consent output has id + recordedAt | `consentContract.post[0,1]` | Postconditions |
| IdentifierType in valid enum | `suppressionContract.pre[0]` | Precondition |
| Consent records immutable | `migrations/008_security_hardening.sql` | DB-level `NO DELETE` + `NO UPDATE` rules |
| Suppression propagates to profiles | `migrations/008_security_hardening.sql` | DB trigger `trg_suppress_profile` |

**Test coverage:** `test/invariants.test.ts` — 14 property-based tests covering all pre/postconditions.

---

### Audit 11 — Hardware / Side-Channel Security

**Principle:** Prevent timing, cache, and power side-channel leakage from cryptographic operations.

**Findings & Mitigations:**

| Finding | File | Resolution |
|---|---|---|
| String equality via `===` allows timing oracle | `utils/crypto.ts` | All auth comparisons use `timingSafeEqual` via Node `crypto` |
| API key length mismatch short-circuits | `utils/crypto.ts` | Length-mismatched comparison still runs `timingSafeEqual` on padded buffer; returns false |
| Early-exit on first matching API key | `middleware/zeroTrust.ts` | Iterates **all** rows before returning; match stored in variable, not returned immediately |
| Auth path faster for valid tokens | `middleware/zeroTrust.ts` | `constantTimeDelay(100ms + jitter)` applied on all auth failures |
| Password hashing with SHA-256 (single round) | `utils/crypto.ts` | `scrypt` with N=16384 used for password derivation |
| Predictable token generation | `utils/crypto.ts` | `randomBytes(32)` from `node:crypto` — CSPRNG |
| CSRF token comparison via `===` | `utils/tokens.ts` | `verifyCsrf()` delegates to `safeEqual()` → `timingSafeEqual` |
