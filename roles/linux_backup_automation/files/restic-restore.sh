#!/usr/bin/env bash
# ==============================================================================
# File        : files/restic-restore.sh
# Description : Interactive CLI helper utility for restoring and mounting Restic snapshots
# Author      : SudoShea
# Version     : 1.8.3
# License     : MIT
# ==============================================================================

set -euo pipefail

RESTIC_REPO="${RESTIC_REPOSITORY:-/var/backups/restic}"
RESTIC_PASS_FILE="${RESTIC_PASSWORD_FILE:-/etc/restic/password}"

export RESTIC_REPOSITORY="${RESTIC_REPO}"
export RESTIC_PASSWORD_FILE="${RESTIC_PASS_FILE}"

usage() {
  cat << EOF
Usage: $(basename "$0") <command> [options]

Commands:
  snapshots, ls           List all available backup snapshots
  find <pattern>          Find specific files across all snapshots
  dump <snapshot> <file>  Stream/extract a single file from a snapshot to stdout
  restore <snapshot> <target_dir>  Restore a full snapshot to target directory
  mount <mountpoint>      Mount the backup repository as a virtual filesystem

Examples:
  sudo ./restic-restore.sh snapshots
  sudo ./restic-restore.sh find "container-state.json"
  sudo ./restic-restore.sh dump latest /etc/systemd/system/restic-backup.service
  sudo ./restic-restore.sh restore latest /tmp/restore-test
  sudo ./restic-restore.sh mount /mnt/restic-mount
EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

COMMAND="$1"
SHIFT_ARGS="${*:2}"

case "${COMMAND}" in
  snapshots|ls)
    echo "[*] Querying snapshots in ${RESTIC_REPOSITORY}..."
    restic snapshots
    ;;

  find)
    if [[ -z "${2:-}" ]]; then
      echo "[!] Error: File pattern required."
      usage
    fi
    echo "[*] Searching for pattern '$2' across all snapshots..."
    restic find "$2"
    ;;

  dump)
    if [[ $# -lt 3 ]]; then
      echo "[!] Error: Snapshot ID and file path required."
      usage
    fi
    SNAPSHOT_ID="$2"
    FILE_PATH="$3"
    echo "[*] Extracting ${FILE_PATH} from snapshot ${SNAPSHOT_ID}..."
    restic dump "${SNAPSHOT_ID}" "${FILE_PATH}"
    ;;

  restore)
    if [[ $# -lt 3 ]]; then
      echo "[!] Error: Snapshot ID and target directory required."
      usage
    fi
    SNAPSHOT_ID="$2"
    TARGET_DIR="$3"
    mkdir -p "${TARGET_DIR}"
    echo "[*] Restoring snapshot ${SNAPSHOT_ID} to ${TARGET_DIR}..."
    restic restore "${SNAPSHOT_ID}" --target "${TARGET_DIR}"
    echo "[+] Restore complete. Files placed in ${TARGET_DIR}"
    ;;

  mount)
    if [[ -z "${2:-}" ]]; then
      echo "[!] Error: Mountpoint directory required."
      usage
    fi
    MOUNTPOINT="$2"
    mkdir -p "${MOUNTPOINT}"
    echo "[*] Mounting repository at ${MOUNTPOINT} (Press Ctrl+C to unmount)..."
    restic mount "${MOUNTPOINT}"
    ;;

  *)
    echo "[!] Unknown command: ${COMMAND}"
    usage
    ;;
esac
