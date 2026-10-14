#!/usr/bin/env bash
set -euo pipefail

API="${API_URL:-http://localhost:3001}"
MAX_RETRIES="${MAX_RETRIES:-5}"
SLEEP="${SLEEP_SEC:-3}"

echo "[health] checking $API/v1/health"
for i in $(seq 1 "$MAX_RETRIES"); do
  STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "$API/v1/health" || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo "[health] OK (attempt $i)"
    exit 0
  fi
  echo "[health] attempt $i — got $STATUS, retrying in ${SLEEP}s…"
  sleep "$SLEEP"
done

echo "[health] FAILED after $MAX_RETRIES attempts"
exit 1
