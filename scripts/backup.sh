#!/bin/sh
# ==============================================================================
# Script      : scripts/backup.sh
# Description : Generates client-side AES-256 encrypted tar archives of homelab
#               container volumes with SHA-256 integrity hashes & 7-day rolling retention.
# Author      : SudoShea
# Version     : 1.4.0
# License     : MIT
# ==============================================================================
set -eu

# Configuration Parameters
BACKUP_DIR="${HOME}/backups"
TARGET_DIR="${HOME}/docker"
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="homelab_backup_${DATE}.tar.gz.gpg"
PASSPHRASE_FILE="${HOME}/.backup_passphrase"
RETENTION_DAYS=7

# Ensure destination directory exists
mkdir -p "${BACKUP_DIR}"

if [ ! -f "${PASSPHRASE_FILE}" ]; then
    echo "❌ Error: Passphrase file missing at ${PASSPHRASE_FILE}" >&2
    exit 1
fi

echo "📦 Starting homelab backup..."

# 1. Archive using Podman User Namespace mapping & encrypt with AES-256
podman unshare tar -czf - -C "${TARGET_DIR}" pihole | \
    gpg --batch --yes --symmetric --cipher-algo AES256 \
    --passphrase-file "${PASSPHRASE_FILE}" \
    -o "${BACKUP_DIR}/${ARCHIVE_NAME}"

# 2. Generate SHA-256 Checksum
cd "${BACKUP_DIR}"	
sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256"

# 3. Maintain 'latest' symlinks for easy automated restores/testing
ln -sf "${ARCHIVE_NAME}" homelab_backup_latest.tar.gz.gpg
ln -sf "${ARCHIVE_NAME}.sha256" homelab_backup_latest.sha256

echo "✅ Backup created successfully: ${BACKUP_DIR}/${ARCHIVE_NAME}"

# 4. Enforce Local Retention (Delete archives older than 7 days)
echo "🧹 Pruning backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -type f -name "homelab_backup_*.tar.gz.gpg" -mtime +"${RETENTION_DAYS}" -delete
find "${BACKUP_DIR}" -type f -name "homelab_backup_*.sha256" -mtime +"${RETENTION_DAYS}" -delete

echo "🎉 Backup process completed!"
