# 🛡️ Linux Backup Automation

[![Ansible Lint](https://github.com/SudoShea/linux-backup-automation/actions/workflows/lint.yml/badge.svg)](https://github.com/SudoShea/linux-backup-automation/actions/workflows/lint.yml)
[![Version](https://img.shields.io/github/v/tag/SudoShea/linux-backup-automation?label=release&color=blue)](https://github.com/SudoShea/linux-backup-automation/tags)
[![Ansible Core](https://img.shields.io/badge/ansible--core-%3E%3D2.15-5BB85C?logo=ansible)](https://docs.ansible.com/ansible/latest/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enterprise-grade, modular Ansible role that deploys automated, encrypted, deduplicated backups using **Restic** and offsite replication using **Rclone** managed via native **systemd** timers.

---

## 🚀 Features

* **Restic Engine:** Fast, deduplicated, authenticated, and encrypted (`AES-256`) local/remote snapshots.
* **Automated Retention:** Enforces prune policies (7 daily, 4 weekly, 12 monthly, 1 yearly).
* **Multi-Cloud Offsite Sync:** Integrated `rclone` synchronisation supporting SFTP, Google Drive, Backblaze B2, AWS S3, and Google Cloud Storage.
* **Native Systemd Integration:** Service and timer units replace legacy crontabs for reliable scheduling, journald logging, and failure handling.
* **CLI Restore Helper Utility:** Ships an interactive helper (`restic-restore.sh`) to `/usr/local/bin` for quick snapshot browsing and file restoration.
* **Independent & Standalone:** Can be imported into any Ansible workflow or run as a standalone deployment.
* **Automated Weekly Restore Verification:** Scheduled systemd timer running a 10% repository data subset integrity check and test restores into an isolated `/tmp` sandbox directory.

---

## 📋 Requirements

* **Target OS:** Debian / Ubuntu, RedHat / RHEL / Fedora.
* **Ansible Core:** `>= 2.15`
* **Privileges:** Root / `sudo` access on target nodes for package installation and systemd unit management.

---

## ⚙️ Role Variables

Default variables are defined in `defaults/main.yml`:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `restic_version` | `"latest"` | Package version or state to install |
| `restic_repository` | `"/var/backups/restic"` | Local/target path for the Restic repo |
| `restic_password_file` | `"/etc/restic/password"` | Path to the Restic repository password file |
| `restic_paths_to_backup` | `["/etc", "/var/lib/containers/storage/volumes"]` | List of host directories to include in snapshots |
| `restic_timer_schedule` | `"*-*-* 02:00:00"` | Systemd calendar expression for backup execution |
| `restic_keep_daily` | `7` | Number of daily snapshots to retain |
| `restic_keep_weekly` | `4` | Number of weekly snapshots to retain |
| `restic_keep_monthly` | `12` | Number of monthly snapshots to retain |
| `restic_keep_yearly` | `1` | Number of yearly snapshots to retain |
| `rclone_offsite_targets` | `[]` | List of offsite remotes configured in `rclone.conf.j2` |
| `restic_verify_enabled` | `true` | Enable automated weekly integrity check and sandbox restore |
| `restic_verify_calendar` | `"Sun *-*-* 03:00:00"` | Systemd timer calendar schedule for verification |
| `restic_verify_data_subset` | `"10%"` | Percentage of repository data packs verified during check |
| `restic_verify_script_path` | `"/usr/local/bin/test-restore.sh"` | Target installation path for verification script |

---

## 📁 Directory Structure

```text
linux-backup-automation/
├── defaults/
│   └── main.yml               # Default role variables & verification settings
├── examples/
│   └── cloud-providers/       # Sample provider vars (gdrive.yml, sftp.yml, b2.yml, etc.)
├── files/
│   └── restic-restore.sh      # Interactive CLI restore utility
├── handlers/
│   └── main.yml               # Systemd daemon-reload handlers
├── meta/
│   └── main.yml               # Galaxy metadata
├── scripts/
│   └── bump_version.py        # Version management script
├── tasks/
│   ├── main.yml               # Role task orchestrator
│   ├── install.yml            # Restic package installation
│   ├── rclone.yml             # Rclone setup and configuration
│   ├── init.yml               # Repository initialisation & password deployment
│   ├── systemd.yml            # Backup systemd service, timer, and wrapper deployment
│   └── verify.yml             # Restore verification pipeline tasks
├── templates/
│   ├── rclone.conf.j2         # Rclone remote definitions
│   ├── restic-backup.sh.j2    # Backup wrapper script with retention & offsite sync
│   ├── restic-backup.service.j2
│   ├── restic-backup.timer.j2
│   ├── test-restore.sh.j2     # Automated 10% data check & sandbox restore script
│   ├── restic-verify.service.j2
│   └── restic-verify.timer.j2
└── tests/                     # Local test harness
    ├── ansible.cfg
    ├── inventory
    ├── roles/
    └── test.yml
```
---

## ⚡ Quick Start (Standalone Usage)

### 1. Install the Role
You can add this role to your project via `requirements.yml`:
```yaml
roles:
  - name: linux_backup_automation
    src: git+https://github.com/SudoShea/linux-backup-automation.git
    version: main
```
or clone it directly into your `roles/` directory:
```bash
git clone https://github.com/SudoShea/linux-backup-automation.git roles/linux_backup_automation
```
### 2. Create a Playbook (`deploy-backups.yml`)
```yaml
---
- hosts: backup_targets
  become: true
  roles:
    - role: linux_backup_automation
      vars:
        restic_repository: "/var/backups/restic"
        restic_password: "{{ vault_restic_password }}"
        restic_paths_to_backup:
          - "/etc"
          - "/var/www"
          - "/var/lib/containers"
        rclone_offsite_targets:
          - name: "gdrive-offsite"
            type: "drive"
            path: "Backups/restic"
            client_id: "{{ vault_gdrive_client_id }}"
            client_secret: "{{ vault_gdrive_client_secret }}"
            token: "{{ vault_gdrive_token }}" 
```
### 3. Run the Playbook
```bash
ansible-playbook -i inventory deploy-backups.yml --ask-vault-pass
```
---

## 🔐 Secrets & Password Management
This role handles two sensitive items that should always be encrypted using **Ansible Vault**:
1. **Restic Repository Password**: Deployed to `/etc/restic/password` with `0600` permissions. Passed via `restic_password`.
2. **Rclone Configuration Tokens**: Rendered into `/etc/rclone/rclone.conf` with `0600` permissions. Passed via individual provider variables or raw token JSON strings.

---

## 🧪 Verification
The role deploys an automated systemd timer (`restic-verify.timer`) that runs weekly (Sunday at 03:00) to execute a 10% data-subset repository integrity check and verify snapshot restoration into an isolated `/tmp` sandbox directory.
**Run manual verification check:**
```bash
sudo /usr/local/bin/test-restore.sh
```
Check verification timer status & schedule:
```bash
sudo systemctl status restic-verify.timer
```
View verification logs via journald:
```bash
sudo journalctl -u restic-verify.service -n 50 --no-pager
```

---

## 🔄 Restoring Backups
The role automatically installs a CLI restore utility on managed target hosts at `/usr/local/bin/restic-restore.sh`.

To interactively view snapshots or restore files on a host:
```bash
# Interactively list snapshots and select items to restore
sudo restic-restore.sh

# Or use standard Restic commands directly
sudo restic -r /var/backups/restic --password-file /etc/restic/password snapshots
sudo restic -r /var/backups/restic --password-file /etc/restic/password restore latest --target /tmp/restore-test
```
---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

