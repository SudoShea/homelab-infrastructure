# Changelog - Linux Backup Automation

All notable changes to the `linux-backup-automation` Ansible role will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-07-30

### Added
* **Automated Restore Verification Pipeline:** Introduced `tasks/verify.yml` along with templates for `test-restore.sh.j2`, `restic-verify.service.j2`, and `restic-verify.timer.j2` to execute weekly 10% data-subset integrity checks and sandboxed restores into `/tmp`.
* **Verification Role Defaults:** Added `restic_verify_enabled`, `restic_verify_calendar`, `restic_verify_data_subset`, and `restic_verify_script_path` configuration variables to `defaults/main.yml`.

### Fixed
* **Systemd Handler Execution in Dry-Run:** Added an explicit `flush_handlers` meta step and `daemon_reload: true` to `tasks/verify.yml` to ensure systemd unit files are registered before timer activation.

---

## [1.0.6] - 2026-07-28

### Added
* **Repository Badges:** Integrated dynamic release version tag and Ansible Core compatibility badges into `README.md`.

### Fixed
* **CI Node Runtime Policy:** Configured `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` environment variable and updated `actions/checkout` to `@v6` in `.github/workflows/lint.yml` to eliminate GitHub runner Node 20 deprecation warnings.

---

## [1.0.5] - 2026-07-28

### Fixed
* **CI Executable Collision:** Streamlined `.github/workflows/lint.yml` by removing redundant manual setup and `pip install` steps that collided with `ansible/ansible-lint@main` binary provisioning.

---

## [1.0.4] - 2026-07-28

### Fixed
* **CI Runner Node Runtime:** Upgraded GitHub Actions `actions/checkout` and `actions/setup-python` to `v5` to eliminate Node 20 deprecation warnings on Node 24 runners.

---

## [1.0.3] - 2026-07-28

### Fixed
* **CI Role Path Resolution:** Added `tests/roles/linux_backup_automation` directory symlink and `tests/ansible.cfg` to enable `ansible-lint` role discovery during test execution syntax checks (`syntax-check`).

---

## [1.0.2] - 2026-07-28

### Fixed
* **Ansible Lint Task Order:** Reordered task keys in `tasks/main.yml` to enforce `name` precedes `become` and `block` (`key-order[task]`).
* **Idempotency Tag:** Added `changed_when: true` to Restic repository initialization command in `tasks/init.yml` (`no-changed-when`).
* **Test Role Import:** Updated `tests/test.yml` to reference `linux_backup_automation` by role name instead of relative directory paths (`role-name[path]`).

---

## [1.0.1] - 2026-07-28

### Fixed
* **Galaxy Role Metadata:** Explicitly defined `role_name: linux_backup_automation` and `namespace: sudoshea` in `meta/main.yml` to meet Galaxy and linting rules.
* **Linting Config:** Added `.ansible-lint` file to enforce production quality rules and exclude test/example files.
* **Workflow Syntax:** Fixed bracket formatting inside `.github/workflows/lint.yml` (`yaml[brackets]`).

---

## [1.0.0] - 2026-07-28

### Added
* **Restic Engine Deployment:** Tasks for automated installation, initialization, and repository configuration using AES-256 encryption.
* **Rclone Integration:** Support for multi-destination offsite synchronization (SFTP, Google Drive, Backblaze B2, AWS S3, GCS).
* **Systemd Automation:** Deployed `restic-backup.service` and `restic-backup.timer` to replace legacy crontabs.
* **Pruning & Retention Policy:** Standardized automated retention rules (7 daily, 4 weekly, 12 monthly, 1 yearly).
* **CLI Restore Utility:** Installed `restic-restore.sh` helper utility to `/usr/local/bin` for interactive snapshot inspection and file recovery.
* **CI Quality Enforcement:** Added `.github/workflows/lint.yml` for automated `ansible-lint` testing and status badge.
* **Modular Provider Examples:** Created example configurations for various cloud storage targets under `examples/cloud-providers/`.
