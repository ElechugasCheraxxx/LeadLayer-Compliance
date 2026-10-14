# LeadLayer API Reference

Base URL: `https://api.example.com/v1`  
Auth: `Authorization: Bearer <API_KEY>` (all routes except `/opt-out`)

---

## Authentication

### POST /auth/signup
```json
{ "email": "string", "password": "string", "fullName": "string" }
```
Returns `{ userId, accessToken, refreshToken }`

### POST /auth/login
```json
{ "email": "string", "password": "string" }
```

### POST /auth/refresh
```json
{ "refreshToken": "string" }
```

---

## Consent

### POST /consent/record
```json
{
  "enrichment": true,
  "collection": true,
  "intent": false,
  "tosVersion": "2025-01-01"
}
```

### PATCH /consent/revoke
```json
{ "consentTypes": ["intent"] }
```

### GET /consent/status
Returns current consent state for authenticated user.

---

## Opt-out (public — no auth required)

### POST /opt-out
```json
{
  "identifierType": "email | linkedin_url | name_company",
  "identifierValue": "string",
  "emailConfirm": "string (optional)"
}
```
Returns `{ success: true, message: "string" }`

### GET /opt-out/verify/:token
Confirms opt-out via email link.

---

## Enrichment (extension)

### POST /enrich/profile
```json
{ "url": "https://linkedin.com/in/...", "source": "linkedin" }
```
**or**
```json
{ "email": "person@company.com" }
```

Response:
```json
{
  "found": true,
  "confidence": 0.87,
  "data": {
    "fullName": "string",
    "email": "string",
    "emailStatus": "verified | inferred | unknown",
    "phone": "string | null",
    "currentTitle": "string",
    "currentCompany": "string",
    "linkedinUrl": "string",
    "location": "string",
    "technologies": ["string"],
    "lastUpdated": "ISO8601"
  }
}
```
If opted out: `{ "found": false, "reason": "opted_out" }`

### GET /enrich/usage
Returns `{ creditsUsed, creditsRemaining, resetAt }`

---

## Data API — requires API key (Fuente 2)

### GET /data/person
Query params: `email=` OR `linkedin_url=` OR `name=&company=`

Same response shape as `/enrich/profile`.

### GET /data/company
Query params: `domain=acme.com`
```json
{
  "name": "string",
  "size": "string",
  "industry": "string",
  "technologies": ["string"],
  "hiringSignal": true
}
```

### POST /data/bulk
```json
{ "queries": [{ "email": "..." }, { "linkedin_url": "..." }] }
```
Max 1,000 queries per request. Async for >100 (returns `jobId`).

### GET /data/usage
Returns `{ callsUsed, callsRemaining, resetAt }`

---

## Intent Data — Enterprise only (Fuente 3)

### GET /intent/signals
Query params: `category=crm_evaluation`, `min_score=50`, `date_range=30d`

```json
{
  "signals": [
    {
      "companyDomain": "string",
      "category": "string",
      "score": 75,
      "signalCount": 12,
      "uniqueEmployees": 3,
      "lastSignal": "ISO8601"
    }
  ]
}
```

### GET /intent/company/:domain
Returns intent history for a single company.

### GET /intent/categories
Returns list of available intent categories.

---

## Rate Limits

| Tier | Enrichments/day | API calls/month |
|---|---|---|
| Free | 10 | — |
| Pro | 500 | — |
| Team | Unlimited | 10,000 |
| Starter API | — | 10,000 |
| Growth API | — | 50,000 |
| Scale API | — | 200,000 |

Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

---

## Error Codes

| Code | HTTP | Meaning |
|---|---|---|
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient tier |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Quota exceeded |
| `OPTED_OUT` | 200 | Profile is suppressed |
| `REGION_NOT_SUPPORTED` | 451 | Geo-blocked region |
| `VALIDATION_ERROR` | 422 | Invalid request body |
