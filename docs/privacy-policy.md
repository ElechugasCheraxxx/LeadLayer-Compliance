# Privacy Policy

**Last updated:** 2025-01-01  
**Responsible party:** [Company Name] — privacy@leadlayer.io

---

## 1. What Data We Collect

### 1a. Data from our own users (extension installers)

| Data | Purpose | Legal basis |
|---|---|---|
| Email, name | Account management | Contract (Art. 11 Ley 29733) |
| Browsing events on supported pages | Enrichment engine improvement | Consent (`consent_collection`) |
| Intent navigation signals | Intent data product (Fuente 3) | Explicit consent (`consent_intent`) |
| Payment info | Billing | Contract via Stripe |

### 1b. Data of third-party contacts (enriched profiles)

We process professional contact data (name, email, job title, company, LinkedIn URL) sourced
exclusively from public web sources (LinkedIn, GitHub, Twitter/X).

**Legal basis:** Art. 13 (legitimate interest) + Art. 14 (publicly accessible sources) Ley 29733.  
**Legitimate interest:** Enabling sales and recruiting professionals to contact relevant people.

## 2. What We Do NOT Collect

- Private messages or DMs
- Passwords or credentials
- Health, financial, or sensitive personal data
- Browsing outside the supported professional platforms (LinkedIn, GitHub, Twitter/X, company sites)

## 3. How We Use Data

| Purpose | Data used |
|---|---|
| Providing enrichment results | Browsing events + public profile data |
| Improving enrichment accuracy | Aggregated usage patterns (with `consent_collection`) |
| Intent data product | Navigation signals (only with `consent_intent = true`) |
| Billing and subscriptions | Email, payment data via Stripe |
| Security and fraud prevention | IP address, user agent |

## 4. Data Sharing

We share data only:
- With **B2B API clients** who query a specific profile (they receive only that profile's data)
- With **sub-processors** listed in our DPA (Hunter.io, Clearbit, Supabase, Railway, Vercel)
- When **required by law** or to enforce our terms

We never sell datasets of personal data. The enrichment API is a query service, not a database sale.

## 5. Data Retention

| Data type | Retention |
|---|---|
| consent_records | Indefinite (immutable compliance log) |
| enrichment_events | 12 months |
| intent_events | 90 days |
| Suppression list | Indefinite |
| Account data | Duration of account + 30 days post-deletion |

## 6. Your Rights (Ley 29733, Art. 19–22)

You have the right to: **access**, **rectify**, **cancel/delete**, and **object** to processing.

To exercise your rights:
- Email: privacy@leadlayer.io
- Opt-out of being enriched (no account needed): https://leadlayer.io/opt-out
- Revoke consent (account required): Dashboard → Privacy settings

We will respond within 15 business days.

## 7. Consent Management

When you install the extension, we show a granular consent modal with three separate options:

1. **Enrichment consent** (required to use the product)
2. **Collection consent** (contribute data to improve the engine)
3. **Intent consent** (optional — share navigation signals for market analysis)

You can revoke any consent at any time from Settings → Privacy.

## 8. Security

We implement TLS 1.2+ in transit, AES-256 at rest, JWT authentication, and immutable audit logs.
We conduct regular dependency vulnerability scans.

## 9. Contact

LeadLayer / [Company Name]  
privacy@leadlayer.io  
https://leadlayer.io/opt-out
