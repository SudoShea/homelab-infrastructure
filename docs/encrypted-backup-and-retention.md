# 🔐 Encrypted Backup & Retention Policy Runbook

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<username>`, `<primary_hostname>`, `<secondary_hostname>`, `<cloud_remote>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.8.1
* **Last Updated:** 2026-07-29

---

## 🎯 1. Objective & Scope

This runbook defines the automated 3-2-1 backup pipeline, client-side encryption model, lifecycle retention schedules, restore testing protocols, and host maintenance standards for all host configurations and persistent container data within the `homelab-infrastructure` stack.

### Backup Target Volume & Paths
The backup engine captures all critical system state and persistent rootless container volumes managed under Ansible:
* **System Configuration:** `/etc/`
* **Container Storage Volumes:** `/var/lib/containers/storage/volumes/`
  * Pi-hole configuration & SQLite databases (`etc-pihole`, `etc-dnsmasq.d`)
  * Unbound recursive DNS configurations (`unbound-config`)

---

## 🛡️ 2. Encryption & 3-2-1 Architecture

All persistent data is chunked, deduplicated, authenticated, and encrypted **client-side before leaving the host**. Unencrypted data never traverses the network or sits on remote secondary storage or cloud targets.

* **Symmetric Encryption Standard:** AES-256-CTR with Poly1305 MAC authentication via **Restic**.
* **Secrets Isolation:** Repository encryption keys and cloud credentials are stored securely in Ansible Vault (`group_vars/all/vault.yml`) and deployed to `/etc/restic/password` (`0600 root:root`).
* **Automation Engine:** Driven by native systemd services and timers deployed via the modular `linux_backup_automation` role.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                              PRIMARY HOST                               │
│                           (<primary_hostname>)                          │
│  1. Restic creates local encrypted snapshot (/var/backups/restic)       │
│  2. Restic prunes older snapshots according to retention policy         │
│  3. Rclone syncs repository blocks directly to offsite remotes:         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (02:00 AM UTC Daily)
                    ┌────────────────┴────────────────────┐
                    ▼                                     ▼
     ┌─────────────────────────────┐       ┌─────────────────────────────┐
     │       SECONDARY HOST        │       │        OFFSITE CLOUD        │
     │   (<secondary_hostname>)    │       │     (<cloud_provider>)      │
     │ SFTP Remote Target          │       │ Cloud Storage Target        │
     └─────────────────────────────┘       └─────────────────────────────┘
```
---

## 📅 3. Retention Schedule & Recovery Metrics

| Stage | Frequency | Retention Schedule | Objective |
| :--- | :--- | :--- | :--- |
| **Local Primary** (`<primary_host>`) | Daily @ 02:00 AM UTC | 7 Daily, 4 Weekly, 12 Monthly, 1 Yearly | Instant local rollback for corrupted volumes or misconfigurations. |
| **Secondary Mirror** (`<secondary_host>`) | Daily @ 02:00 AM UTC | 7 Daily, 4 Weekly, 12 Monthly, 1 Yearly | On-premises hardware fault tolerance (SFTP remote). |
| **Offsite Cloud** (`<cloud_provider>`) | Daily @ 02:00 AM UTC | 7 Daily, 4 Weekly, 12 Monthly, 1 Yearly | Offsite disaster recovery via `rclone sync`. |

* Recovery Point Objective (RPO): `< 24 hours` (Nightly automated snapshot schedule).
* Recovery Time Objective (RTO): `< 15` minutes to inspect, unpack snapshot volumes, and launch container stacks via Ansible.

---

## ⚙️ 4. Automated Backup Script

**Systemd Timer Execution** (restic-backup.service` / `restic-backup.timer`)
Executes daily at 02:00 AM UTC on target nodes:
1. **Snapshot Creation**: Restic captures an encrypted, deduplicated snapshot of defined backup source paths (`/etc`, `/var/lib/containers/storage/volumes`).
2. **Automated Pruning**: Enforces retention policy via `restic forget --prune` using configured flags:
`--keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 1`.
3. **Offsite Replication**: Executes rclone sync to mirror snapshot blocks to secondary SFTP nodes and cloud remotes defined in `/etc/rclone/rclone.conf`.

---

## 🔓 5. Decryption & Restore Procedure

In the event of volume corruption, file loss, or host restoration, follow these steps to inspect and restore persistent state:

### Interactive Restore Helper Utility
Run the interactive CLI helper shipped to managed nodes:
```bash
sudo restic-restore.sh
```
### Manual CLI Restore Procedure
Step 1: Verify Repository Integrity
```bash
sudo restic -r /var/backups/restic --password-file /etc/restic/password check
```
Step 2: List Available Snapshots
```bash
sudo restic -r /var/backups/restic --password-file /etc/restic/password snapshots
```
Step 3: Restore Snapshot Volumes
```bash
# Restore latest snapshot to target path
sudo restic -r /var/backups/restic --password-file /etc/restic/password \
    restore latest --target / --include /var/lib/containers/storage/volumes
```
Step 4: Restart Infrastructure Stack
```bash
ansible-playbook -i inventory.ini site.yml -K
```
---

## 🧪 6. Verification & Integrity Testing
* **Automated Integrity Checks**: `restic check` runs natively during backup processing to verify repository index locks and data blob hashes.
* **Restore Dry-Run Testing*: Run `restic-restore.sh` or mount repository snapshots locally to verify readable state without touching live production volumes:
```bash
sudo mkdir -p /mnt/restic-test
sudo restic -r /var/backups/restic --password-file /etc/restic/password mount /mnt/restic-test
```
---

## 🧹 7. Host Security & Automated Maintenance Policy
To ensure managed nodes remain secure without risking container downtime:
* **Debian / Ubuntu Security Patches**: `unattended-upgrades` automatically applies security patches daily (`/etc/apt/apt.conf.d/20auto-upgrades`).
* **RHEL / Fedora Security Patches**: `dnf-automatic` manages automated system package updates via systemd timer (`dnf-automatic.timer`).
* **Disk Space Protection**: Restic's deduplication and `prune` passes prevent backup repository growth from consuming root filesystems.
* **Weekly Maintenance**: Scheduled package cleanup runs every Sunday at 04:00 AM (`apt` or `dnf` autoremove and clean).

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
