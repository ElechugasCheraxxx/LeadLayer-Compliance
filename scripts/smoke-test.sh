#!/usr/bin/env bash
# Smoke test post-deploy: auth + enrich + health
set -euo pipefail

API="${API_URL:-https://api.leadlayer.io}"
EMAIL="smoketest+$(date +%s)@leadlayer.io"
PASSWORD="SmokeTest123!"

fail() { echo "[FAIL] $1"; exit 1; }
ok()   { echo "[OK]   $1"; }

# 1. Health
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "$API/v1/health")
[ "$STATUS" = "200" ] && ok "health" || fail "health returned $STATUS"

# 2. Signup
RESP=$(curl -sf -X POST "$API/v1/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" || echo '{}')
echo "$RESP" | grep -q '"id"' && ok "signup" || fail "signup: $RESP"

# 3. Login
RESP=$(curl -sf -X POST "$API/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" || echo '{}')
TOKEN=$(echo "$RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
[ -n "$TOKEN" ] && ok "login" || fail "login: $RESP"

# 4. Enrich usage (no credits needed)
RESP=$(curl -sf "$API/v1/enrich/usage" -H "Authorization: Bearer $TOKEN" || echo '{}')
echo "$RESP" | grep -q '"credits_used"' && ok "enrich/usage" || fail "enrich/usage: $RESP"

echo ""
echo "✅ Smoke tests passed — $API"
