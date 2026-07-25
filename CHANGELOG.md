# Changelog

All notable changes to the `homelab-infrastructure` project will be documented in this file.

## [1.6.1] - 2026-07-26

### Fixed
- Fixed Ansible linter module resolution by replacing `ansible.builtin.ini_file` with `community.general.ini_file` in `roles/logging_shipper`.
- Removed obsolete self-signed TLS generation task from `roles/logging_server` to enforce local Root CA deployment and ensure task idempotency.
- Corrected extra blank line formatting in `roles/logging_server/tasks/main.yml`.

## [1.6.0] - 2026-07-26

### Added
- Integrated centralised observability stack featuring **Loki** (log indexing engine), **Grafana** (HTTPS UI), and **Vector** (systemd journald log shipper).
- Enabled native TLS support on port `3000` for Grafana, secured by the local homelab Root CA (`rootCA.pem`).
- Added `roles/logging_server` and `roles/logging_shipper` Ansible roles for automated stack deployment.
- Added automated repository versioning script (`scripts/bump-version.sh`) supporting tracked and untracked templates (`.j2`, `.toml`, `.conf`, `.ini`, `.json`).
- Published comprehensive documentation guide at `docs/logging-and-grafana-setup.md`.

## [1.5.0] - 2026-07-25

### Added
* Multi-OS support across Debian/Ubuntu and RHEL/Fedora hosts (`dnf-automatic`, automated package cleanup timers).
* Dynamic architecture detection for Unbound container images (`aarch64` vs `x86_64`).
* Support for Pi-hole v6 replication via Nebula Sync configuration task.

### Changed
* **Repository Sanitization**: Fully sanitised all playbooks, configs, inventory, and documentation files to replace user-specific credentials, IPs, hostnames, and paths with generic placeholders (`<item>`).
* **SELinux Compatibility**: Added `:z` volume flags to Podman volume mounts for RHEL/CentOS/Fedora compatibility.
* **Documentation Standards**: Updated all runbooks (`topology-and-disaster-recovery.md`, `encrypted-backup-and-retention.md`, `pihole-v6-tls-setup.md`, `README.md`) with explicit user instructions on configuration placeholders, command flags (`-K`), and setup prerequisites.

## [1.4.0] - 2026-07-25

### Added
* Authored `docs/pihole-v6-tls-setup.md` runbook defining Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals.

## [1.3.0] - 2026-07-24

### Removed
* **Caddy Reverse Proxy:** Completely removed the Caddy container, associated data directories, and legacy proxy routing roles/templates in favor of native service architecture.

### Added
* **Native Pi-hole v6 HTTPS:** Configured Pi-hole's built-in Civetweb webserver to natively serve HTTPS traffic on port 443 using custom local CA-signed `tls.pem` certificates.
* **Automated Certificate Deployment:** Documented local root CA workflows and automated renewal scripts for updating Pi-hole TLS certificates.

### Changed
* **Network Topology & Documentation:** Updated `docs/topology-and-disaster-recovery.md` and `README.md` to remove Caddy from the architecture and reflect native Pi-hole v6 TLS container port bindings (`443/tcp`).

## [1.2.0] - 2026-07-24
### Added
- Created `scripts/backup.sh` to generate client-side AES-256 encrypted snapshots using `podman unshare`.
- Created `scripts/test-restore.sh` to perform SHA-256 verification and isolated dry-run extractions into `/tmp/restore_test`.
- Authored `docs/encrypted-backup-and-retention.md` runbook defining 3-2-1 backup architecture, RPO/RTO metrics, and verification standards.
- Configured automated host security updates via `unattended-upgrades` on Pi host.

## [1.1.0] - 2026-07-24
### Added
- Created `docs/topology-and-disaster-recovery.md` covering edge-to-core network topology, Podman container isolation boundaries, cold-boot restore steps, and RTO/RPO objectives.

## [1.0.1] - 2026-07-24
### Added
- Jinja2 configuration templates for Unbound recursive DNS (`unbound.conf.j2`) and Caddy reverse proxy (`Caddyfile.j2`).
- Sample `inventory.ini` for local and remote deployment targets.

## [1.0.0] - 2026-07-24
### Added
- Initial release of Ansible-driven Rootless Podman Homelab Stack.
- Provisioning roles for containerized Pi-hole, Unbound recursive DNS, and Caddy reverse proxy.
- Integrated automated GitHub Actions workflow for `ansible-lint` CI validation.
