# Changelog

All notable changes to the `homelab-infrastructure` project will be documented in this file.

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
