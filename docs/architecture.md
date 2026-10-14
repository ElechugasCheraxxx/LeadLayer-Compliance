# LeadLayer — Architecture

## Overview

LeadLayer is a monorepo micro-SaaS with 3 revenue sources (SaaS, Data API, Intent Data) delivered through browser extensions and a B2B API.

```
[USER BROWSER]
  Extension (Chrome / Safari / Firefox)
  ├── ConsentModal (Capa 1 — granular consent on first use)
  ├── Content Script (detects LinkedIn/GitHub/Twitter, renders overlay)
  ├── Background Worker (auth, intent events gated behind consent_intent)
  └── Side Panel (history, saved contacts, privacy settings)
        │
        │ HTTPS/JWT
        ▼
[API GATEWAY]  api.leadlayer.io  (Fastify on Railway)
  ├── Geo-block middleware (EU/UK → 451)
  ├── Feature flags (Redis kill switches)
  ├── Auth (Supabase JWT)
  ├── Enrichment Service
  │     ├── Suppression check (ALWAYS first — fail-closed)
  │     ├── Redis cache (24h TTL)
  │     ├── Hunter.io (circuit breaker)
  │     └── Clearbit (circuit breaker)
  ├── Consent Service (immutable log)
  ├── Intent Engine (only users with consent_intent=true)
  ├── B2B API (processor model, no bulk dump)
  └── Billing (Stripe)
        │
        ▼
[DATA LAYER]
  PostgreSQL 16   — users, contacts, consent_records (RLS), suppression_list
  Redis 7         — rate limits, cache, circuit breakers, feature flags
  ClickHouse 24   — intent_events, intent_scores (materialized view, 30d window)
```

## Key Architectural Decisions

| ADR | Decision | Rationale |
|---|---|---|
| 001 | Processor model — no bulk DB export | Legal: DL 1700 Art. 12-A |
| 002 | Suppression check synchronous, fail-closed | No race condition can expose suppressed data |
| 003 | consent_records immutable (no DELETE/UPDATE) | MINJUSDH audit trail |
| 004 | Circuit breakers on Hunter + Clearbit | Provider outage ≠ total failure |
| 005 | Redis kill switches for all features | Ops: any feature off in <1s |
| 006 | Distroless runtime container | No shell post-exploitation |
| 007 | API keys HMAC-SHA256, shown once | DB breach ≠ key exposure |
| 008 | EU/UK geo-block (CF-IPCountry) | GDPR out of scope |
| 009 | Intent pipeline gated by local storage check | Zero non-consenting data in pipeline |
| 010 | PostgreSQL RLS on user tables | Cross-user data isolation |

## Data Flow — Enrichment Request

```
1. Content script detects LinkedIn profile URL
2. Check local consent (chrome.storage) — no consent → show ConsentModal
3. Send ENRICH_PROFILE to background worker
4. Background → POST /v1/enrich/profile (JWT)
5. API: suppression_list check (fail-closed)
6. API: Redis cache lookup (HIT → return cached)
7. API: concurrent Hunter.io + Clearbit (each via CircuitBreaker)
8. API: merge results, score, cache 24h
9. Response → overlay rendered in page
```

## Intent Data Flow (Fuente 3)

```
1. Background worker detects tab navigation
2. Check consent_intent (local storage — synchronous, no network)
3. If false → STOP (zero events sent for non-consenting users)
4. categorizeUrl(url) → maps domain to intent category
5. POST /v1/intent/event (JWT)
6. INSERT into ClickHouse intent_events
7. Materialized view intent_scores refreshes (30d window)
8. Enterprise clients query /v1/intent/signals
```

## Geo-blocking

```
Cloudflare CF-IPCountry header → checked on every request
EU + UK → HTTP 451 (Unavailable For Legal Reasons)
Target regions: LATAM, USA (ex-CA early stage), APAC
```

## Monorepo Structure

```
leadlayer/
├── apps/
│   ├── extension-chrome/     Manifest V3 — Chrome, Brave, Opera
│   ├── extension-safari/     Swift host + JS bridge — macOS + iOS
│   ├── extension-firefox/    Manifest V2 + webextension-polyfill
│   ├── api/                  Fastify — Railway
│   ├── dashboard/            Next.js 14 — Vercel
│   └── admin/                Internal ops panel
├── packages/
│   ├── shared-types/         ConsentRecord, Profile, API types
│   ├── core/                 Merger, scorer, suppression, quality (shared logic)
│   └── ui/                   Shared React components
└── infrastructure/
    ├── railway/              Service config + Dockerfile
    └── scripts/              migrate.ts, seed-db.ts, backup.sh
```
