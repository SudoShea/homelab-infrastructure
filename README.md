# Rootless Podman Homelab Stack 🏠

![Ansible Linting](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)

An Infrastructure-as-Code repository for provisioning a rootless container stack (Pi-hole v6, Unbound recursive DNS, and centralized Loki/Grafana logging with Vector) managed via Podman across Debian/RHEL systems, featuring automated 3-2-1 AES-256 encrypted backups, native TLS, and host maintenance.

**Note for Users**: Before deploying this stack, ensure you update `inventory.ini` and configuration templates with your environment's specific IP addresses, hostnames, and credentials.

---

## ⚡ Architecture

* **Rootless Podman**: Serves container workloads without root privilege escalation.
* **Pi-hole v6 (DNS Filter & Native HTTPS)**: Network-wide ad blocking, local DNS resolution, and embedded Civetweb TLS support.
* **Unbound (Recursive DNS)**: Direct root-server DNS resolver with multi-architecture image detection (`aarch64`, `x86_64`).
* **Centralized Observability Stack**: Centralized log aggregation via Vector (journald shipper), Loki (log indexing engine), and Grafana (TLS-encrypted dashboards).
* **Multi-OS Host Support**: Automated maintenance for both Debian/Ubuntu (`unattended-upgrades`) and RHEL/Fedora (`dnf-automatic`).
* **3-2-1 Encrypted Backup**: Nightly client-side AES-256 GPG snapshots, weekly restore verification, and automated offsite sync to cloud storage via `rclone`.

---

## 🛠️ Repository Structure
```text
homelab-infrastructure/
├── .github/workflows/lint.yml            # Ansible-lint CI workflow
├── docs/
│   ├── encrypted-backup-and-retention.md # Backup runbook & RPO/RTO metrics
│   ├── logging-and-grafana-setup.md      # Centralized logging pipeline & Grafana HTTPS guide
│   ├── pihole-v6-tls-setup.md            # Native Pi-hole v6 HTTPS setup & local Root CA guide
│   └── topology-and-disaster-recovery.md # Network topology & disaster recovery runbook
├── roles/
│   ├── logging_server/                   # Loki log engine & Grafana dashboard provisioning
│   ├── logging_shipper/                  # Vector log collection agent service
│   └── podman_stack/                     # Core Pi-hole, Unbound, & backup automation tasks
├── scripts/
│   ├── backup.sh                         # Nightly AES-256 container snapshot script
│   ├── bump-version.sh                   # Automated version and date header update tool
│   └── test-restore.sh                   # Weekly dry-run restore verification test
├── inventory.ini                         # Deployment inventory target
├── CHANGELOG.md                          # Version release history
├── README.md                             # Project documentation
└── site.yml                              # Playbook entrypoint
```
---

## 📖 Runbooks & Documentation

| Document | Description |
|---|---|
| [`docs/encrypted-backup-and-retention.md`](docs/encrypted-backup-and-retention.md) | 3-2-1 Backup Architecture, AES-256 GPG encryption, SHA-256 verification, & restore testing |
| [`docs/topology-and-disaster-recovery.md`](docs/topology-and-disaster-recovery.md) | Homelab network topology, container boundaries, health checks, & cold-boot recovery |
| [`docs/pihole-v6-tls-setup.md`](docs/pihole-v6-tls-setup.md) | Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals |
| [`docs/logging-and-grafana-setup.md`](docs/logging-and-grafana-setup.md) | Centralized logging pipeline (Vector → Loki → Grafana), local Root CA HTTPS setup, & dashboard provisioning |

---

## 🚀 Quick Start

### 1. Clone Repository & Install Prerequisites
Ensure Ansible and the `containers.podman` collection are installed on your control node:
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

ansible-galaxy collection install containers.podman
```
### 2. Configure Inventory Target
Before running the deployment, ensure your environment-specific details are set:
* `inventory.ini`: Update with your target host IPs, SSH users, and host aliases.
* `roles/podman_stack/tasks/main.yml`: Update container environment variables such as `TZ` (timezone), `FTLCONF_webserver_domain`, and (if using Nebula Sync) primary/replica cluster credentials.
* `site.yml`: Verify your storage server targets and cloud backup remote paths.

### 3. Run Dry-Run Check (Safe Mode)
Verify tasks and template rendering against your target system without applying changes:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff -K
```
### 4. Deploy Stack
Execute the playbook to provision persistent volumes, templates, rootless containers, backup cron jobs, and host security tasks:
```bash
ansible-playbook -i inventory.ini site.yml -K
```

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
