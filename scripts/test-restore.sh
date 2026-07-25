#!/bin/sh
# ==============================================================================
# Script      : scripts/test-restore.sh
# Description : Performs automated checksum verification and isolated dry-run
#               decryption/extraction tests on the latest homelab backup.
# Author      : SudoShea
# Version     : 1.6.1
# License     : MIT
# ==============================================================================
set -eu

BACKUP_DIR="${HOME}/backups"
PASSPHRASE_FILE="${HOME}/.backup_passphrase"
LATEST_BACKUP="${BACKUP_DIR}/homelab_backup_latest.tar.gz.gpg"
TEST_DIR="/tmp/restore_test"

if [ ! -f "${LATEST_BACKUP}" ]; then
    echo "❌ Error: No backup found at ${LATEST_BACKUP}" >&2
    exit 1
fi

echo "🧪 Starting backup verification & dry-run restore..."

# Step 1: Verify SHA-256 Checksum
echo "[1/4] Verifying SHA-256 checksum..."
cd "${BACKUP_DIR}"
sha256sum -c homelab_backup_latest.sha256

# Step 2: Test Decryption Stream & Archive Headers
echo "[2/4] Testing GPG decryption stream..."
gpg --batch --decrypt --passphrase-file "${PASSPHRASE_FILE}" "${LATEST_BACKUP}" | tar -tzf - > /dev/null
echo "   ↳ Header and stream verification passed!"

# Step 3: Dry-Run Extraction into /tmp/restore_test
echo "[3/4] Performing dry-run extraction into ${TEST_DIR}..."
rm -rf "${TEST_DIR}"
mkdir -p "${TEST_DIR}"

gpg --batch --decrypt --passphrase-file "${PASSPHRASE_FILE}" "${LATEST_BACKUP}" | \
    podman unshare tar -xzf - -C "${TEST_DIR}"

# Step 4: Validate Critical Files
echo "[4/4] Validating extracted container state..."
if [ -f "${TEST_DIR}/pihole/etc-pihole/pihole-FTL.db" ]; then
    echo "   ↳ Pi-hole FTL database verified intact!"
else
    echo "❌ Error: Expected files missing in restore output!" >&2
    rm -rf "${TEST_DIR}"
    exit 1
fi

# Cleanup using podman unshare to match container sub-UID permissions
podman unshare rm -rf "${TEST_DIR}"
echo "🎉 Dry-run restore test completed successfully!"
