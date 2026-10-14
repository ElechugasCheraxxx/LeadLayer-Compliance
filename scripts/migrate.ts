#!/usr/bin/env tsx
import { readdir, readFile } from 'fs/promises'
import { join } from 'path'
import postgres from 'postgres'

const sql = postgres(process.env.DATABASE_URL!)

async function migrate() {
  await sql`
    CREATE TABLE IF NOT EXISTS _migrations (
      id        SERIAL PRIMARY KEY,
      filename  TEXT UNIQUE NOT NULL,
      ran_at    TIMESTAMPTZ DEFAULT now()
    )
  `

  const dir = join(import.meta.dirname, '../apps/api/src/db/migrations')
  const files = (await readdir(dir)).filter(f => f.endsWith('.sql')).sort()

  for (const file of files) {
    const [{ count }] = await sql`SELECT count(*) FROM _migrations WHERE filename = ${file}`
    if (Number(count) > 0) { console.log(`skip  ${file}`); continue }

    const content = await readFile(join(dir, file), 'utf8')
    await sql.begin(tx => [tx.unsafe(content)])
    await sql`INSERT INTO _migrations (filename) VALUES (${file})`
    console.log(`ran   ${file}`)
  }

  await sql.end()
  console.log('Migrations complete.')
}

migrate().catch(err => { console.error(err); process.exit(1) })
