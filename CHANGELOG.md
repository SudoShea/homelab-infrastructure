# Changelog

All notable changes to the `homelab-infrastructure` project will be documented in this file.

## [1.4.0] - 2026-07-25

### Added
- Authored `docs/pihole-v6-tls-setup.md` runbook defining Native Pi-hole v6 HTTPS setup, local Root CA generation, & automated cert renewals.

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
