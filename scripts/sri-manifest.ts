import { createHash } from 'node:crypto'
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join, resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dir = dirname(fileURLToPath(import.meta.url))
const DIST = resolve(__dir, '../../apps/dashboard/.next/static')

function sha384(buf: Buffer): string {
  return 'sha384-' + createHash('sha384').update(buf).digest('base64')
}

function walkDir(dir: string): string[] {
  const entries = readdirSync(dir, { withFileTypes: true })
  return entries.flatMap((e) => {
    const full = join(dir, e.name)
    return e.isDirectory() ? walkDir(full) : [full]
  })
}

const files = walkDir(DIST).filter((f) => f.endsWith('.js') || f.endsWith('.css'))
const manifest: Record<string, string> = {}

for (const file of files) {
  const buf = readFileSync(file)
  const relative = file.replace(DIST + '/', '')
  manifest[relative] = sha384(buf)
  console.log(`✓ ${relative}`)
}

console.log('\nSRI Manifest:')
console.log(JSON.stringify(manifest, null, 2))

export { manifest }
