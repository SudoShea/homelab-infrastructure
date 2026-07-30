# Changelog

All notable changes to the `homelab-infrastructure` project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.8.3] - 2026-07-30

### Changed
* **Backup Automation Upgrade:** Pinned `linux_backup_automation` role dependency to `v1.1.0` in `requirements.yml` to integrate the automated weekly Restic integrity check and sandbox restore verification pipeline (`test-restore.sh` script, `restic-verify.service`, and `restic-verify.timer`).
* **Ansible Configuration Modernization:** Updated `ansible.cfg` to use native `result_format = yaml` callback formatting under `[callback_default]` (replacing the deprecated `community.general.yaml` callback) and enabled automatic `.vault_pass` file loading via `vault_password_file`.

### Documentation
* **Repository Architecture & Tree:** Updated `README.md` to document the automated restore verification pipeline and aligned the repository layout tree with on-disk paths (`ansible.cfg`, `group_vars/homelab/backup.yml`).

---

## [1.8.2] - 2026-07-29

### Added
* **Vault Template:** Created `group_vars/all/vault.yml.example` to provide a clean, unencrypted reference template for Restic passphrases, Rclone OAuth tokens, and Grafana credentials.

### Changed
* **Parameterised Backup Target Variables:** Updated `group_vars/homelab_nodes/backup.yml` to replace hardcoded IP addresses and SSH usernames with dynamic inventory variables (`secondary_storage_host` and `secondary_storage_user`).
* **Inventory Structure Standardisation:** Harmonised host group hierarchies across `inventory.ini` and `inventory.local.ini` using `[primary_servers]`, `[secondary_servers]`, and `[homelab_nodes]`.
* **Repository Onboarding Guide:** Updated `README.md` Quick Start steps to document copying `inventory.local.ini` and initialising encrypted Ansible Vault files from `vault.yml.example`.

### Fixed
* **CI Runner Node Runtime Policy:** Added `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` environment flag and updated `actions/checkout` to `@v6` in `.github/workflows/lint.yml` to eliminate GitHub runner Node 20 deprecation warnings.

### Security
* **Vault Exclusion Rules:** Enhanced `.gitignore` with rules (`group_vars/**/vault.yml`, `host_vars/**/vault.yml`) to ensure local encrypted vault files are excluded from Git history while allowing `.example` templates.

---

## [1.8.1] - 2026-07-29

### Changed
* **Backup Engine Integration:** Migrated persistent container volume backup architecture to use Restic and Rclone managed via the `linux_backup_automation` Ansible role.
* **Encrypted Backup Runbook:** Updated `docs/encrypted-backup-and-retention.md` to detail Restic client-side AES-256 encryption, systemd daily timer schedules, retention pruning policy (7 daily, 4 weekly, 12 monthly, 1 yearly), and interactive `restic-restore.sh` recovery workflows.
* **Topology & Disaster Recovery:** Updated `docs/topology-and-disaster-recovery.md` with current container storage volume paths (`/var/lib/containers/storage/volumes/`), health diagnostic checks, and cold-boot restoration steps using Restic.
* **Repository README:** Updated `README.md` with standardised repository badges (Ansible Lint, Version tag, Ansible Core compatibility, and MIT License), updated directory layout, and `requirements.yml` setup procedures.

### Removed
* **Legacy Reverse Proxy References:** Completely purged obsolete references to Caddy across topology, disaster recovery, and backup runbooks to reflect direct Pi-hole v6 management.

---

## [1.8.0] - 2026-07-26

### Added
* **Centralized Observability:** Integrated Vector journald log shipping to Loki indexing engine and Grafana dashboard visualisation.
* **Pi-hole v6 HTTPS:** Native TLS support for Pi-hole v6 web interface with automated certificate management.
* **Rootless Quadlets:** Converted core DNS services (Pi-hole and Unbound) to native Podman Quadlet systemd container definitions.

---

## [1.7.0] - 2026-07-26

### Added
- **Podman Quadlet Architecture**: Migrated `roles/podman_stack` from legacy `podman_container` tasks to declarative Podman Quadlets (`pihole.container.j2`, `unbound.container.j2`), enabling native systemd user service lifecycle management with linger enabled.
- **Deployment Wrapper Script**: Added `scripts/run.sh` to provide a unified CLI interface supporting dry-run checks (`check`), targeted host runs (`run <target>`), and full inventory deployments (`all`).
- **Python Versioning & Header Tooling**: Introduced `scripts/bump_version.py` replacing `bump-version.sh` to automate semantic version bumps (`patch`, `minor`, `major`), git tag creation, and header metadata sync across all templates (`.j2`), scripts (`.sh`, `.py`), playbooks (`.yml`), and configuration files (`.ini`, `.toml`, `.json`).

### Changed
- **Ansible Fact & Header Standardization**: Refactored playbook and task files to use explicit `ansible_facts[...]` dictionary references to eliminate top-level variable deprecation warnings, and standardized all file headers (File, Description, Author, Version, License).
- **Legacy Unit Cleanup**: Updated `roles/podman_stack/tasks/main.yml` to automatically detect and purge non-Quadlet user systemd units (`pihole.service`, `unbound.service`) to prevent service override conflicts.
- **Documentation & Runbooks**: Updated `README.md` to document Quadlet architecture, systemd management commands (`systemctl --user`), the new script suite, and updated repository structure.

---

## [1.6.1] - 2026-07-26

### Fixed
- Fixed Ansible linter module resolution by replacing `ansible.builtin.ini_file` with `community.general.ini_file` in `roles/logging_shipper`.
- Removed obsolete self-signed TLS generation task from `roles/logging_server` to enforce local Root CA deployment and ensure task idempotency.
- Corrected extra blank line formatting in `roles/logging_server/tasks/main.yml`.

---

## [1.6.0] - 2026-07-26

### Added
- Integrated centralised observability stack featuring **Loki** (log indexing engine), **Grafana** (HTTPS UI), and **Vector** (systemd journald log shipper).
- Enabled native TLS support on port `3000` for Grafana, secured by the local homelab Root CA (`rootCA.pem`).
- Added `roles/logging_server` and `roles/logging_shipper` Ansible roles for automated stack deployment.
- Added automated repository versioning script (`scripts/bump-version.sh`) supporting tracked and untracked templates (`.j2`, `.toml`, `.conf`, `.ini`, `.json`).
- Published comprehensive documentation guide at `docs/logging-and-grafana-setup.md`.

---

## [1.5.0] - 2026-07-25

### Added
* Multi-OS support across Debian/Ubuntu and RHEL/Fedora hosts (`dnf-automatic`, automated package cleanup timers).
* Dynamic architecture detection for Unbound container images (`aarch64` vs `x86_64`).
* Support for Pi-hole v6 replication via Nebula Sync configuration task.

### Changed
* **Repository Sanitization**: Fully sanitised all playbooks, configs, inventory, and documentation files to replace user-specific credentials, IPs, hostnames, and paths with generic placeholders (`<item>`).
* **SELinux Compatibility**: Added `:z` volume flags to Podman volume mounts for RHEL/CentOS/Fedora compatibility.
* **Documentation Standards**: Updated all runbooks (`topology-and-disaster-recovery.md`, `encrypted-backup-and-retention.md`, `pihole-v6-tls-setup.md`, `README.md`) with explicit user instructions on configuration placeholders, command flags (`-K`), and setup prerequisites.

---

## [1.4.0] - 2026-07-25

### Added
* Authored `docs/pihole-v6-tls-setup.md` runbook defining Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals.

---

## [1.3.0] - 2026-07-24

### Removed
* **Caddy Reverse Proxy:** Completely removed the Caddy container, associated data directories, and legacy proxy routing roles/templates in favor of native service architecture.

### Added
* **Native Pi-hole v6 HTTPS:** Configured Pi-hole's built-in Civetweb webserver to natively serve HTTPS traffic on port 443 using custom local CA-signed `tls.pem` certificates.
* **Automated Certificate Deployment:** Documented local root CA workflows and automated renewal scripts for updating Pi-hole TLS certificates.

### Changed
* **Network Topology & Documentation:** Updated `docs/topology-and-disaster-recovery.md` and `README.md` to remove Caddy from the architecture and reflect native Pi-hole v6 TLS container port bindings (`443/tcp`).

---

## [1.2.0] - 2026-07-24
### Added
- Created `scripts/backup.sh` to generate client-side AES-256 encrypted snapshots using `podman unshare`.
- Created `scripts/test-restore.sh` to perform SHA-256 verification and isolated dry-run extractions into `/tmp/restore_test`.
- Authored `docs/encrypted-backup-and-retention.md` runbook defining 3-2-1 backup architecture, RPO/RTO metrics, and verification standards.
- Configured automated host security updates via `unattended-upgrades` on Pi host.

---

## [1.1.0] - 2026-07-24
### Added
- Created `docs/topology-and-disaster-recovery.md` covering edge-to-core network topology, Podman container isolation boundaries, cold-boot restore steps, and RTO/RPO objectives.

---

## [1.0.1] - 2026-07-24
### Added
- Jinja2 configuration templates for Unbound recursive DNS (`unbound.conf.j2`) and Caddy reverse proxy (`Caddyfile.j2`).
- Sample `inventory.ini` for local and remote deployment targets.

---

## [1.0.0] - 2026-07-24
### Added
- Initial release of Ansible-driven Rootless Podman Homelab Stack.
- Provisioning roles for containerized Pi-hole, Unbound recursive DNS, and Caddy reverse proxy.
- Integrated automated GitHub Actions workflow for `ansible-lint` CI validation.
