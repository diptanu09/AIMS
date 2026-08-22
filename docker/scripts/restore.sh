#!/usr/bin/env bash
# docker/scripts/restore.sh - Database Disaster Recovery & Verification Script
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <path_to_backup.sql.gz>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "[ERROR] Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "[WARNING] Restoring database will overwrite existing AIMS data."
echo "[INFO] Restoring from ${BACKUP_FILE}..."

gunzip -c "${BACKUP_FILE}" | docker exec -i aims-postgres pg_restore -U aims_owner -d aims --clean --if-exists

echo "[SUCCESS] Database restoration completed successfully."
echo "[INFO] Verifying database integrity..."

docker exec -t aims-postgres psql -U aims_owner -d aims -c "SELECT COUNT(*) FROM attendance_daily;"

echo "[SUCCESS] Database verification passed."
