# Data Processing Agreement

**Version:** 1.0 — 2026-01-15  
**Between:** [Client Company] ("Controller") and LeadLayer / [Company Name] ("Processor")

---

## 1. Subject Matter

This Data Processing Agreement ("DPA") forms part of the LeadLayer Terms of Service and governs the processing of personal data by LeadLayer on behalf of the Controller in connection with the enrichment API service.

## 2. Roles

| Party | Role | Scope |
|---|---|---|
| Client (you) | Data Controller | Determines which profiles to query |
| LeadLayer | Data Processor | Processes enrichment queries on your behalf |

## 3. Nature and Purpose of Processing

LeadLayer processes professional contact data (name, email, job title, company, LinkedIn URL) exclusively to return enrichment results to the Controller. No data is transferred as a dataset — each API call is an ephemeral query.

**Permitted purposes:** B2B sales outreach, recruiting, account-based marketing.  
**Prohibited purposes:** Consumer marketing, harassment, resale of raw data.

## 4. Data Subjects

Professional individuals whose public profile data is processed: prospects, candidates, and business contacts queried by the Controller via the enrichment API.

## 5. Types of Personal Data

- Full name
- Professional email address
- Job title and seniority
- Employer name and domain
- LinkedIn profile URL
- Geographic location (city/country level)

## 6. Processor Obligations

LeadLayer shall:

a) Process data only on documented instructions from the Controller (API queries).  
b) Ensure confidentiality obligations on all personnel with access.  
c) Implement technical and organisational measures per Section 8.  
d) Assist the Controller with data subject rights requests (access, erasure, portability) within 72 hours of notification.  
e) Notify the Controller without undue delay (and within 72 hours where feasible) of any personal data breach.  
f) Make available all information necessary to demonstrate compliance and allow audits with 30 days notice.  
g) Delete or return all personal data upon termination of the agreement.

## 7. Sub-processors

LeadLayer uses the following sub-processors:

| Sub-processor | Purpose | Location |
|---|---|---|
| Hunter.io | Email verification | USA |
| Clearbit / HubSpot | Company enrichment | USA |
| Supabase | Database hosting | USA (AWS) |
| Railway | API hosting | USA (GCP) |
| Vercel | Dashboard hosting | USA |
| Cloudflare | CDN / DDoS protection | USA |
| Stripe | Billing | USA |

LeadLayer will notify the Controller of any intended sub-processor changes with 30 days notice.

## 8. Technical and Organisational Measures

- TLS 1.2+ in transit, AES-256 at rest
- JWT authentication; API keys stored as HMAC-SHA256 hashes only
- PostgreSQL Row Level Security on all user data tables
- Immutable consent audit log (no DELETE permitted)
- Suppression list checked before every enrichment response
- Distroless production containers (no shell access)
- Circuit breakers on external data providers
- Geo-blocking for non-target jurisdictions

## 9. Suppression / Opt-Out

Any data subject may request suppression at `https://leadlayer.io/opt-out`. Once verified, their identifier is added to an immutable suppression list and all future enrichment queries for that identifier return `{ found: false, reason: "opted_out" }`. The Controller is responsible for honouring opt-outs received via their own channels.

## 10. International Transfers

Data is processed in the USA under Standard Contractual Clauses (EU SCCs module 2, processor to controller, available on request) where applicable. LeadLayer does not actively serve EU/EEA customers.

## 11. Term and Termination

This DPA is effective for the duration of the Controller's active subscription. Upon termination, LeadLayer will delete all Controller-associated data within 30 days.

## 12. Governing Law

This DPA is governed by the laws of Peru (Ley 29733) for Peruvian-registered Controllers, or Delaware, USA for all others.

---

**Signed by Controller:** ___________________ Date: ___________  
**Signed by Processor (LeadLayer):** ___________________ Date: ___________

Send signed copy to: legal@leadlayer.io
