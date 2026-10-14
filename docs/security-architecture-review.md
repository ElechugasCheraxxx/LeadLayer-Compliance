# LeadLayer — Security Architecture Review
## Audit 6: Secure Architecture Decision Record (ADR)

---

### THREAT MODEL

**Assets**
| Asset | Sensitivity | Owner |
|---|---|---|
| User PII (email, behavior) | High | Users |
| API keys | Critical | B2B customers |
| Consent records | High — immutable legal log | LeadLayer |
| Suppression list | High — legal obligation | Third parties |
| Intent event stream | High | Users with consent_intent=true |
| Enrichment cache | Medium | LeadLayer |

**Threat Actors**
| Actor | Capability | Motivation |
|---|---|---|
| Automated scraper | HTTP at scale | Free API access |
| Competitor | API key brute-force | Data theft |
| Malicious B2B customer | Over-querying bulk | Full DB extraction |
| Compromised dependency | Code execution | Supply chain |
| Regulatory auditor | Evidence collection | Compliance |
| Disgruntled employee | Insider access | Data exfiltration |

---

### DECISION RECORD

#### ADR-001: Processor model (not Controller)
**Decision:** LeadLayer acts as data processor, not controller.  
**Consequence:** No bulk DB export endpoints. `/data/bulk` capped at 1,000. 
No "download all contacts" feature. Each query is ephemeral.  
**Audit:** Audit 2 (Non Viable) — selling a database dump would be non-viable under DL 1700 Art. 12-A.

---

#### ADR-002: Suppression check is synchronous and fail-closed
**Decision:** Every enrichment call checks suppression_list **before** any data is returned.  
If the check throws, the enrichment fails (fail-closed, not fail-open).  
**Consequence:** Suppression consistency is a hard invariant; no race condition can expose suppressed data.  
**Audit:** Audits 1 (Fail Stop) + 10 (Formal Verification).

---

#### ADR-003: Consent records are immutable
**Decision:** `consent_records` table has `NO DELETE` and `NO UPDATE` rules at DB level.  
New state is always a new INSERT.  
**Consequence:** Full audit trail for regulatory inspection. Cannot be accidentally or maliciously erased.  
**Audit:** Audit 10 (Formal Verification), Audit 2 (Non Viable — MINJUSDH requirement).

---

#### ADR-004: Circuit breakers on external providers
**Decision:** Hunter.io and Clearbit calls are wrapped in CircuitBreaker backed by Redis.  
On 5 consecutive failures, circuit opens for 30s.  
**Consequence:** Provider outage does not cascade to total API failure. Graceful degradation.  
**Audit:** Audit 1 (Fail Stop).

---

#### ADR-005: Kill switches for all revenue-generating features
**Decision:** `enrichment`, `b2b-api`, `bulk-api`, `intent`, `data-collection`, `signup` are all kill-switchable via Redis.  
Admin endpoint requires ADMIN_SECRET (not JWT — separate credential).  
**Consequence:** Any feature can be disabled in <1s without deployment.  
**Audit:** Audit 5 (Kill Switch).

---

#### ADR-006: Distroless runtime container
**Decision:** Production image is `gcr.io/distroless/nodejs20-debian12:nonroot`.  
**Consequence:** No shell, no package manager, no cron. Reduces attack surface by ~80% vs debian:slim.  
Post-exploitation is severely limited: attacker cannot install tools, spawn shells, or exfiltrate via common methods.  
**Audit:** Audit 9 (Runtime Exploitability).

---

#### ADR-007: API keys hashed with HMAC-SHA256 (never stored plaintext)
**Decision:** Raw key shown once on creation. Only HMAC-SHA256 hash stored.  
Verification is constant-time via `timingSafeEqual`.  
**Consequence:** DB compromise does not expose API keys. Timing attacks against key verification are mitigated.  
**Audit:** Audits 3 (Zero Trust) + 11 (Side-Channel).

---

#### ADR-008: EU/UK geo-block from day 1
**Decision:** Cloudflare `CF-IPCountry` header is checked on every request.  
EU + UK countries receive HTTP 451 (Unavailable For Legal Reasons).  
**Consequence:** GDPR enforcement risk is zero. Compliance scope is Ley 29733 + LATAM only.  
**Audit:** Audit 2 (Non Viable — GDPR fines are existential for a bootstrapped SaaS).

---

#### ADR-009: Intent data only from users with explicit opt-in
**Decision:** `consent_intent = true` is checked in the background service worker **before** any navigation event is sent.  
Check is local (chrome.storage) — no network call — so it is synchronous and reliable.  
**Consequence:** Zero risk of including non-consenting user behavior in intent pipeline. Provable in code audit.  
**Audit:** Audits 2 (Non Viable), 3 (Zero Trust), 10 (Formal — background worker invariant).

---

#### ADR-010: Row-Level Security on user data tables
**Decision:** `saved_contacts` and `enrichment_events` have PostgreSQL RLS enabled.  
Policy: `user_id = current_setting('app.current_user_id')`.  
**Consequence:** Even with a compromised DB query (e.g., via a secondary injection vector), a user cannot read another user's data.  
**Audit:** Audit 6 (Secure Architecture).

---

### RESIDUAL RISKS

| Risk | Severity | Mitigation | Residual |
|---|---|---|---|
| LinkedIn DOM change breaks extension | Medium | CI E2E + 24h fix SLA | Low |
| Redis compromise exposes rate-limit keys | Low | Keys are non-PII prefixed counts | Negligible |
| Clearbit/Hunter key leaked via env | High | Secret rotation in Railway; no env in logs | Medium |
| Intent data re-identification | Medium | user_id hashed + not reversible in ClickHouse schema | Low |
| Insider bulk-export | High | RLS + no bulk-dump endpoint + audit log | Medium |
