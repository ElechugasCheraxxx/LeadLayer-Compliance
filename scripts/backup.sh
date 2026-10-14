#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUCKET="${BACKUP_BUCKET:-leadlayer-backups}"
FILE="pg_backup_${TIMESTAMP}.dump"
TMP="/tmp/${FILE}"

echo "Starting backup: ${FILE}"

pg_dump \
  --format=custom \
  --no-acl \
  --no-owner \
  "${DATABASE_URL}" \
  > "${TMP}"

echo "Dump size: $(du -sh ${TMP} | cut -f1)"

if command -v aws &>/dev/null; then
  aws s3 cp "${TMP}" "s3://${BUCKET}/${FILE}"
  echo "Uploaded to s3://${BUCKET}/${FILE}"
elif command -v gsutil &>/dev/null; then
  gsutil cp "${TMP}" "gs://${BUCKET}/${FILE}"
  echo "Uploaded to gs://${BUCKET}/${FILE}"
else
  echo "WARNING: No cloud CLI found. Backup saved locally at ${TMP}"
  exit 0
fi

rm "${TMP}"

# Prune backups older than 30 days
if command -v aws &>/dev/null; then
  CUTOFF=$(date -d '30 days ago' +%Y%m%d 2>/dev/null || date -v-30d +%Y%m%d)
  aws s3 ls "s3://${BUCKET}/" | while read -r _ _ _ key; do
    KEY_DATE=$(echo "${key}" | grep -oE '[0-9]{8}' | head -1)
    if [[ -n "${KEY_DATE}" && "${KEY_DATE}" < "${CUTOFF}" ]]; then
      aws s3 rm "s3://${BUCKET}/${key}"
      echo "Pruned: ${key}"
    fi
  done
fi

echo "Backup complete."
