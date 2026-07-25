# 🔐 Encrypted Backup & Retention Policy Runbook

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<username>`, `<primary_hostname>`, `<secondary_hostname>`, `<cloud_remote>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.6.1
* **Last Updated:** 2026-07-26

---

## 🎯 1. Objective & Scope

This runbook defines the automated 3-2-1 backup pipeline, client-side encryption model, lifecycle retention schedules, restore testing protocols, and host maintenance standards for all persistent container data within the `homelab-infrastructure` stack.

### Backup Target Volume
* **Path:** `~/homelab/`
  * `pihole/etc-pihole/` & `pihole/etc-dnsmasq.d/` (Pi-hole configuration & databases)
  * `unbound/config/` (Unbound DNS recursive configuration)

---

## 🛡️ 2. Encryption & 3-2-1 Architecture

All persistent data is archived and encrypted **client-side before leaving the host**. Unencrypted data never traverses the network or sits on remote cloud storage.

* **Symmetric Encryption Standard:** AES-256 via GnuPG (`gpg`).
* **Namespace Isolation:** Utilizes `podman unshare` to capture rootless container sub-UID volumes without requiring elevated `sudo` privileges.

```text
 ┌──────────────────────┐         ┌──────────────────────┐         ┌──────────────────────┐
 │     Primary Host     │  rsync  │    Secondary Host    │ rclone  │    Offsite Cloud     │
 │ (<primary_hostname>) ├────────►│(<secondary_hostname>)├────────►│(<cloud_provider>)    │
 │ Snapshot & Encrypt   │  03:00  │ Local Copy Mirror    │  03:00  │ Encrypted Offsite    │
 └──────────────────────┘         └──────────────────────┘         └──────────────────────┘
```
---

## 📅 3. Retention Schedule & Recovery Metrics

| Stage | Frequency | Retention Window | Storafe Footprint | Objective |
| :--- | :--- | :--- | :--- | :--- |
| **Local Primary** (`<primary_host>`) | Daily @ 02:00 AM | 7 Days | ~230MB | Fast local rollback for corrupted volumes or misconfigurations. |
| **Secondary Mirror** (`<secondary_host>`) | Daily @ 03:00 AM | 7 Days | ~230MB | On-premises hardware fault tolerance. |
| **Offsite Cloud** (`<cloud_provider>`) | Daily @ 03:00 AM | 7 Days | ~230MB | Offsite disaster recovery via `rclone sync`. |

* Recovery Point Objective (RPO): `< 24 hours` (Nightly automated snapshots).
* Recovery Time Objective (RTO): `< 15` minutes to decrypt, unpack, and launch the stack.

---

## ⚙️ 4. Automated Backup Script

**Backup Execution** (`scripts/backup.sh`)
Executes daily at 02:00 AM on `<primary_host>`:

1. Archives `~/homelab/` volumes using `podman unshare`.
2. Encrypts stream using AES-256 GPG with symmetric passphrase.
3. Generates a matching `.sha256` checksum file.
4. Enforces 7-day rolling local retention by deleting older archives (`-mtime +7`).

**Offsite Replication Schedule** (`cron`)
* 03:00 AM Daily (`<secondary_host`): Pulls backups from `<primary_host` via `rsync -az` and immediately syncs them offsite using `rclone sync`.
```bash
rclone sync  /home/<username>/backups/pihole/ <cloud_remote>:<cloud_backup_path>/`.
```
---

## 🔓 5. Decryption & Restore Procedure

In the event of data loss or host restoration, follow these steps to decrypt and unpack persistent state:

### Step 1: Verify Checksum Integrity
```bash
sha256sum -c homelab_backup_YYYYMMDD_HHMMSS.tar.gz.gpg.sha256
```
### Step 2: Decrypt Archive
```bash
gpg --batch --decrypt --passphrase-file ~/.backup_passphrase \
    -o homelab_restored.tar.gz /path/to/homelab_backup_YYYYMMDD_HHMMSS.tar.gz.gpg
```
### Step 3: Unpack Persistent Data
```bash
podman unshare tar -xzf homelab_restored.tar.gz -C ~/
```
### Step 4: Restart Stack
```bash
ansible-playbook -i inventory.ini site.yml -K
```
---

## 🧪 6. Verification & Integrity Testing
**Automated Dry-Run Test** (`scripts/test-restore.sh`)
Executes automatically every Sunday at 02:30 AM via `cron`:

1. Verifies the latest `.sha256` checksum against the `.gpg` archive
2. Decrypts and performs a dry-run extraction into an isolated temporary directory (`/tmp/restore_test`).
3. Confirms database and configuration file readability (`pihole-FTL.db`, `unbound.conf`).
4. Cleans up temporary artifacts cleanly without touching live volumes.

---

## 🧹 7. Host Security & Automated Maintenance Policy
To ensure the primary host remains secure without risking container downtime:
* **Debian / Ubuntu Security Patches**: `unattended-upgrades` automatically downloads and applies security patches daily (`/etc/apt/apt.conf.d/20auto-upgrades`).
* **RHEL / Fedora Security Patches**: `dnf-automatic` manages automated system package updates via systemd timer (`dnf-automatic.timer`).
* **Disk Space Protection**: Automatic removal of unused dependencies.
* **Weekly Maintenance**: Scheduled weekly system update and package cleanup runs every Sunday at 04:00 AM (`apt` or `dnf` autoremove and clean).

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
