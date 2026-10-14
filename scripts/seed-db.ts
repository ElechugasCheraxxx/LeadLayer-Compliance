#!/usr/bin/env tsx
import postgres from 'postgres'
import { randomUUID } from 'crypto'

const sql = postgres(process.env.DATABASE_URL ?? 'postgresql://leadlayer:password@localhost:5432/leadlayer')

async function seed() {
  console.log('Seeding dev data…')

  const userId = randomUUID()
  const teamId = randomUUID()

  await sql`
    INSERT INTO users (id, email, supabase_auth_id, full_name, subscription_tier)
    VALUES (${userId}, 'dev@leadlayer.io', 'dev-supabase-id', 'Dev User', 'enterprise')
    ON CONFLICT (email) DO NOTHING
  `

  await sql`
    INSERT INTO teams (id, name, owner_id, plan_seats)
    VALUES (${teamId}, 'Dev Team', ${userId}, 10)
    ON CONFLICT DO NOTHING
  `

  await sql`
    INSERT INTO team_members (team_id, user_id, role, accepted_at)
    VALUES (${teamId}, ${userId}, 'owner', now())
    ON CONFLICT DO NOTHING
  `

  await sql`
    INSERT INTO consent_records (user_id, consent_enrichment, consent_collection, consent_intent, tos_version, ip_address)
    VALUES (${userId}, true, true, false, '2026-01-15', '127.0.0.1')
    ON CONFLICT DO NOTHING
  `

  const profiles = [
    { name: 'Jane Smith', email: 'jane@acme.com', title: 'VP of Sales', company: 'Acme Corp', url: 'https://linkedin.com/in/janesmith', score: 0.91 },
    { name: 'Carlos Mendez', email: 'carlos@techco.io', title: 'Head of Engineering', company: 'TechCo', url: 'https://github.com/carlosmendez', score: 0.76 },
    { name: 'Aiko Tanaka', email: null, title: 'Recruiter', company: 'Startup XYZ', url: 'https://linkedin.com/in/aikotanaka', score: 0.44 },
  ]

  for (const p of profiles) {
    await sql`
      INSERT INTO profiles (source_url, source_type, full_name, email, current_title, current_company, confidence_score)
      VALUES (${p.url}, 'linkedin', ${p.name}, ${p.email}, ${p.title}, ${p.company}, ${p.score})
      ON CONFLICT (source_url) DO NOTHING
    `
  }

  console.log('Seed complete.')
  await sql.end()
}

seed().catch(err => { console.error(err); process.exit(1) })
