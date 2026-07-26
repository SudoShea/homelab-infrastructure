# Rootless Podman Homelab Stack 🏠

![Ansible Linting](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)

An Infrastructure-as-Code (IaC) repository for provisioning a rootless container stack (Pi-hole v6, Unbound recursive DNS, and centralised Loki/Grafana logging with Vector) managed natively via **Podman Quadlets** across Debian and RHEL systems. Features automated 3-2-1 AES-256 encrypted backups, native TLS, and automated host maintenance.

> **Note for Users**: Before deploying this stack, ensure you update `inventory.ini` and configuration templates with your environment's specific IP addresses, hostnames, and credentials.

---

## ⚡ Architecture

* **Podman Quadlets**: Native systemd integration using declarative `.container` and `.network` definitions running under unprivileged user accounts with linger enabled.
* **Pi-hole v6 (DNS Filter & Native HTTPS)**: Network-wide ad blocking, local DNS resolution, and embedded web server support.
* **Unbound (Recursive DNS)**: Direct root-server DNS resolver with dynamic architecture detection (`aarch64` / `x86_64`) forwarding queries to root servers securely over port `5335`.
* **Centralised Observability Stack**: Centralised log aggregation via Vector (journald shipper), Loki (indexing engine), and Grafana (TLS-encrypted dashboards).
* **Multi-OS Host Support**: Automated security patching for both Debian/Ubuntu (`unattended-upgrades`) and RHEL/Fedora (`dnf-automatic`).
* **3-2-1 Encrypted Backup**: Nightly client-side AES-256 encrypted snapshots, weekly restore verification tests, and automated offsite cloud sync via `rclone`.

---

## 🛠️ Repository Structure
```text
homelab-infrastructure/
├── .github/workflows/lint.yml         # Ansible-lint CI workflow
├── docs/
│   ├── encrypted-backup-and-retention.md # Backup runbook & RPO/RTO metrics
│   ├── logging-and-grafana-setup.md      # Centralised logging pipeline & Grafana HTTPS guide
│   ├── pihole-v6-tls-setup.md            # Native Pi-hole v6 HTTPS setup & local Root CA guide
│   └── topology-and-disaster-recovery.md # Network topology & disaster recovery runbook
├── roles/
│   ├── logging_server/                   # Loki log engine & Grafana dashboard provisioning
│   ├── logging_shipper/                  # Vector log collection agent service
│   └── podman_stack/                     # Core Pi-hole, Unbound Quadlets, & backup automation
├── scripts/
│   ├── backup.sh                         # Nightly AES-256 container snapshot script
│   ├── bump_version.py                   # Version bump & automated file header sync script
│   ├── run.sh                            # Deployment wrapper script (check/run modes)
│   └── test-restore.sh                   # Weekly dry-run restore verification test
├── CHANGELOG.md                          # Version release history
├── inventory.ini                         # Production deployment target template
├── inventory.local.ini                   # Local testing inventory target (git-ignored)
├── LICENSE                               # MIT License
├── README.md                             # Project documentation
├── site.yml                              # Master playbook entrypoint
└── VERSION                               # Current release version tag
```
---

## 📖 Runbooks & Documentation

| Document | Description |
|---|---|
| [`docs/encrypted-backup-and-retention.md`](docs/encrypted-backup-and-retention.md) | 3-2-1 Backup Architecture, AES-256 GPG encryption, SHA-256 verification, & restore testing |
| [`docs/topology-and-disaster-recovery.md`](docs/topology-and-disaster-recovery.md) | Homelab network topology, container boundaries, health checks, & cold-boot recovery |
| [`docs/pihole-v6-tls-setup.md`](docs/pihole-v6-tls-setup.md) | Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals |
| [`docs/logging-and-grafana-setup.md`](docs/logging-and-grafana-setup.md) | Centralised logging pipeline (Vector → Loki → Grafana), local Root CA HTTPS setup, & dashboard provisioning |

---

## 🚀 Quick Start

### 1. Prerequisites
Ensure Ansible and the required collections are installed on your control node:
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

ansible-galaxy collection install containers.podman
```
### 2. Configure Inventory & Variables
Set your environment specifics:
* `inventory.ini`: Update with your target host IPs, SSH users, and host aliases.
* `roles/podman_stack/tasks/main.yml`: Update container environment variables such as `TZ` (timezone), `FTLCONF_webserver_domain`, and (if using Nebula Sync) primary/replica cluster credentials.
* `site.yml`: Verify play-to-play mappings, storage server targets, and cloud back remote paths.

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
