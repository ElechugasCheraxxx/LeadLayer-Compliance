#!/usr/bin/env node
/**
 * Supply Chain Audit — verifies pnpm-lock.yaml integrity and flags:
 *  1. packages installed from git refs (not registries)
 *  2. packages with no integrity hash
 *  3. packages from non-npmjs.com registries
 *
 * Usage: node infrastructure/scripts/supply-chain-audit.mjs
 * Exit code: 0 = clean, 1 = violations found
 */

import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import { createHash } from 'crypto'

const __dir = dirname(fileURLToPath(import.meta.url))
const LOCK = resolve(__dir, '../../pnpm-lock.yaml')

const raw = readFileSync(LOCK, 'utf8')
const lines = raw.split('\n')

const violations = []
let pkg = null

for (const line of lines) {
  const pkgMatch = line.match(/^  (.+):$/)
  if (pkgMatch) { pkg = pkgMatch[1]; continue }

  if (line.includes('resolution:') && line.includes('github:')) {
    violations.push(`[GIT_REF] ${pkg} resolved from git — use registry`)
  }
  if (line.includes('resolution:') && !line.includes('integrity')) {
    violations.push(`[NO_HASH] ${pkg} has no integrity hash`)
  }
  if (line.includes('registry:') && !line.includes('registry.npmjs.org') && !line.includes('registry.yarnpkg.com')) {
    violations.push(`[ALT_REGISTRY] ${pkg} — non-standard registry`)
  }
}

// checksum the lockfile itself for drift detection
const hash = createHash('sha256').update(raw).digest('hex')
console.log(`lock-hash: ${hash}`)

if (violations.length > 0) {
  console.error('\nSupply Chain Violations:')
  violations.forEach(v => console.error(` ✗ ${v}`))
  process.exit(1)
} else {
  console.log(`✓ supply-chain clean (${lines.length} lines checked)`)
}
