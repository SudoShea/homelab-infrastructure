# Rootless Podman Homelab Stack 🏠

![Ansible Linting](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)

An Ansible-driven Infrastructure-as-Code repository for provisioning a rootless container stack (Pi-hole, and Unbound recursive DNS) managed via Podman, featuring automated 3-2-1 AES-256 encrypted backups and host maintenance.

---

## ⚡ Architecture

* **Rootless Podman:** Serves container workloads without root privilege escalation.
* **Pi-hole (DNS Filter):** Network-wide ad blocking and local DNS resolution.
* **Unbound (Recursive DNS):** Direct root-server DNS resolver (bypasses upstream ISP/third-party tracking).
* **3-2-1 Encrypted Backup:** Nightly client-side AES-256 GPG snapshots, weekly restore verification, and automated offsite sync to Google Drive via `rclone`.
* **Automated Host Maintenance:** Unattended security patching via `unattended-upgrades` with automated storage cleanup.

---

## 🛠️ Repository Structure
```text
homelab-infrastructure/
├── .github/workflows/lint.yml   # Ansible-lint CI workflow
├── docs/
│   ├── encrypted-backup-and-retention.md # Backup runbook & RPO/RTO metrics
│   └── topology-and-disaster-recovery.md # Network topology & disaster recovery runbook
├── roles/podman_stack/
│   ├── tasks/main.yml           # Core provisioning & backup automation tasks
│   └── templates/
│       └── unbound.conf.j2      # Unbound recursive DNS config
├── scripts/
│   ├── backup.sh                # Nightly AES-256 container snapshot script
│   └── test-restore.sh          # Weekly dry-run restore verification test
├── inventory.ini                # Deployment inventory target
├── CHANGELOG.md                 # Version release history
├── README.md                    # Project documentation
└── site.yml                     # Playbook entrypoint
```
---

## 📖 Runbooks & Documentation

| Document | Description |
|---|---|
| [`docs/encrypted-backup-and-retention.md`](docs/encrypted-backup-and-retention.md) | 3-2-1 Backup Architecture, AES-256 GPG encryption, SHA-256 verification, & restore testing |
| [`docs/topology-and-disaster-recovery.md`](docs/topology-and-disaster-recovery.md) | Homelab network topology, container boundaries, health checks, & cold-boot recovery |

---

## 🚀 Quick Start

### 1. Clone Repository & Install Prerequisites
Ensure Ansible and the `containers.podman` collection are installed on your control node:
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

ansible-galaxy collection install containers.podman
```
### 2. Run Dry-Run Check (Safe Mode)
Verify tasks and template rendering against your target system without applying changes:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff
```
### 3. Deploy Stack
Execute the playbook to provision persistent volumes, templates, rootless containers, backup cron jobs, and maintenance tasks:
```bash
ansible-playbook -i inventory.ini site.yml
```

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
