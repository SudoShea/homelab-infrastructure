# Rootless Podman Homelab Stack 🏠

[![Ansible Lint](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml)
[![Version](https://img.shields.io/github/v/tag/SudoShea/homelab-infrastructure?label=release&color=blue)](https://github.com/SudoShea/homelab-infrastructure/tags)
[![Ansible Core](https://img.shields.io/badge/ansible--core-%3E%3D2.15-5BB85C?logo=ansible)](https://docs.ansible.com/ansible/latest/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enterprise-grade Infrastructure-as-Code (IaC) repository for provisioning a rootless container stack (**Pi-hole v6**, **Unbound recursive DNS**, and centralised **Loki / Grafana** logging with **Vector**) managed natively via **Podman Quadlets** across Debian and RHEL systems. Features automated 3-2-1 AES-256 encrypted Restic backups, native TLS encryption, and automated host maintenance.

> **Note for Users**: Before deploying this stack, ensure you update `inventory.ini` and configuration variables with your environment's specific IP addresses, hostnames, and encrypted secrets in Ansible Vault.

---

## ⚡ Architecture

* **Podman Quadlets:** Native systemd integration using declarative `.container` and `.network` definitions running under unprivileged user accounts with linger enabled.
* **Pi-hole v6 (DNS Filter & Native HTTPS):** Network-wide ad blocking, local DNS resolution, and embedded web server support with native TLS.
* **Unbound (Recursive DNS):** Direct root-server DNS resolver with dynamic architecture detection (`aarch64` / `x86_64`) forwarding queries to root servers securely over port `5335`.
* **Centralized Observability Stack:** Log aggregation via Vector (journald shipper), Loki (indexing engine), and Grafana (TLS-encrypted dashboards).
* **Multi-OS Host Support:** Automated security patching for both Debian/Ubuntu (`unattended-upgrades`) and RHEL/Fedora (`dnf-automatic`).
* **3-2-1 Encrypted Backup Engine:** Automated, deduplicated, AES-256 encrypted snapshots using Restic, managed by native systemd daily timers and offsite multi-cloud replication via Rclone (`linux_backup_automation` Ansible role).

---

## 🛠️ Repository Structure
```text
homelab-infrastructure/
├── .github/workflows/lint.yml         # Ansible-lint CI workflow
├── docs/
│   ├── encrypted-backup-and-retention.md # Restic backup runbook & RPO/RTO metrics
│   ├── logging-and-grafana-setup.md      # Centralized logging pipeline & Grafana HTTPS guide
│   ├── pihole-v6-tls-setup.md            # Native Pi-hole v6 HTTPS setup & local Root CA guide
│   └── topology-and-disaster-recovery.md # Network topology & disaster recovery runbook
├── roles/
│   ├── logging_server/                   # Loki log engine & Grafana dashboard provisioning
│   ├── logging_shipper/                  # Vector log collection agent service
│   └── podman_stack/                     # Core Pi-hole & Unbound Quadlet provisioning
├── scripts/
│   ├── bump_version.py                   # Version bump & automated file header sync script
│   └── run.sh                            # Deployment wrapper script (check/run modes)
├── CHANGELOG.md                          # Version release history
├── inventory.ini                         # Production deployment target template
├── inventory.local.ini                   # Local testing inventory target (git-ignored)
├── LICENSE                               # MIT License
├── README.md                             # Project documentation
├── requirements.yml                      # External Ansible Galaxy role dependencies
├── site.yml                              # Master playbook entrypoint
└── VERSION                               # Current release version tag
```
---

## 📖 Runbooks & Documentation

| Document | Description |
|---|---|
| [`docs/encrypted-backup-and-retention.md`](docs/encrypted-backup-and-retention.md) | 3-2-1 Restic Architecture, AES-256 encryption, retention pruning & CLI restore utility |
| [`docs/topology-and-disaster-recovery.md`](docs/topology-and-disaster-recovery.md) | Homelab network topology, container boundaries, health checks, & cold-boot recovery |
| [`docs/pihole-v6-tls-setup.md`](docs/pihole-v6-tls-setup.md) | Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals |
| [`docs/logging-and-grafana-setup.md`](docs/logging-and-grafana-setup.md) | Centralised logging pipeline (Vector → Loki → Grafana),  HTTPS setup, & dashboard provisioning |

---

## 🚀 Quick Start

### 1. Prerequisites
Clone the repository and install the required Ansible Galaxy collections and external role dependencies:
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

ansible-galaxy install -r requirements.yml
```
### 2. Configure Inventory & Variables
Set up your target environment and encrypted secrets:
* **Inventory Configuration:** Copy `inventory.ini` or create `inventory.local.ini` with your target host IPs and SSH usernames:
```bash
cp inventory.ini inventory.local.ini
```
* **Vault Secrets Setup:** Initialise your encrypted secrets file from the template:
```bash
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
nano group_vars/all/vault.yml
ansible-vault encrypt group_vars/all/vault.yml
```
*Populate `vault.yml` with your Restic passphrase, Rclone tokens, and Grafana credentials.*
* **Playbook Mappings:** Verify play-to-play mappings, target storage hosts, and backup path definitions in `site.yml`.

### 3. Run Dry-Run Check (Safe Mode)
Run a full check against all inventory targets using the deployment wrapper script:
```bash
./scripts/run.sh check
```
### 4. Deploy Stack
Deploy to a specific host target or across the entire inventory:
```bash
# Deploy to primary node only
./scripts/run.sh run pihole-primary

# Deploy across all inventory nodes
./scripts/run.sh all
```
---

## ⚙️ Quadlet Container Management
Once deployed, container lifecycles are managed natively by `systemd` user services on each node:
```bash
# Check status of the Quadlet stack
systemctl --user status pihole.service unbound.service

# Restart the DNS stack
systemctl --user restart pihole.service

# View live container logs
journalctl --user -u pihole.service -f
```
---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
