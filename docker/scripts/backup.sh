#!/usr/bin/env bash
# docker/scripts/backup.sh - Automated PostgreSQL Backup Procedure
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/aims}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/aims_backup_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

echo "[INFO] Starting AIMS database backup at ${TIMESTAMP}..."

docker exec -t aims-postgres pg_dump -U aims_owner -d aims -F c | gzip > "${BACKUP_FILE}"

echo "[SUCCESS] Backup completed successfully: ${BACKUP_FILE}"

# Retain daily backups for 30 days
find "${BACKUP_DIR}" -type f -name "aims_backup_*.sql.gz" -mtime +30 -delete

echo "[INFO] Backup retention cleanup completed."
