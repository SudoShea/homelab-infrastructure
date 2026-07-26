# 🗺️ Homelab Network Topology & Disaster Recovery Runbook

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<github_username>`, `<primary_storage_node>`, `<cloud_storage_provider>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.7.0
* **Last Updated:** 2026-07-26

---

## 📐 1. Network Topology & Traffic Flow

### Core Architecture Overview
The homelab environment operates on a segmented local network. External web traffic is routed natively via HTTPS to Pi-hole v6, while all host DNS requests are handled locally by Pi-hole chained directly to Unbound for recursive upstream resolution.

```text
[ Local Clients ]
        │
        ├─── HTTPS / HTTP Requests (Port 443 / 80) ────► [ Pi-hole Native Web & TLS (v6) ]
        │                                                        │
        │                                                        │ (Internal Forward: 127.0.0.1#5335)
        │                                                        ▼
        └─── DNS Queries (Port 53) ──────────────────────► [ Pi-hole DNS Filter ]
                                                                 │
                                                                 ▼
                                                        [ Unbound Recursive DNS ]
                                                                 │
                                                                 ▼
                                                        (Direct Root Server Queries)
```
---

## 🔒 2. Container Isolation Boundaries
All service containers run rootless under Podman, managed by the non-privileged system user (ansible_facts['user_id']).

| Service | Container Name | Host Network Port | Sub-System Function | Mount Point / Persistence |
| :--- | :--- | :--- | :--- | :--- |
| **Pi-hole** | `pihole` | `53/udp`, `53/tcp`, `80/tcp` | DNS Filtering & Ad-blocking | `~/homelab/pihole/etc-pihole`<br>`~/homelab/pihole/etc-dnsmasq.d` |
| **Unbound** | `unbound` | `5335/udp` (Loopback) | Recursive Root DNS Resolver | `~/homelab/unbound/config` |

---

## 🚨 3. Disaster Recovery Protocol
Service Level Objectives

* **Recovery Time Objective (RTO):** `< 15 minutes` to restore DNS and core internal web routing after complete node or storage failure.
* **Recovery Point Objective (RPO):** `< 24 hours` (Nightly automated AES-256 snapshots).

**Step-by-Step Cold-Boot Recovery Procedure**
In the event of a catastrophic host crash, OS reinstall, or drive replacement, follow these steps to restore the full stack:

### Step 1: System Onboarding & Ansible Setup
Ensure the target host is reachable via SSH, Python 3 is installed, and user lingering is active:
```bash
# Clone the repository
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

# Install required Podman collection
ansible-galaxy collection install containers.podman
```
### Step 2: Restore Persistent Volume Data
Fetch the latest encrypted backup archive from your local mirror (`<primary_storage_node>`) or offsite cloud (`<cloud_storage_provider>`), verify checksums, and extract using `podman unshare` (see [`docs/encrypted-backup-and-retention.md`](docs/encrypted-backup-and-retention.md)):
```bash
# 1. Verify SHA-256 Checksum Integrity
sha256sum -c homelab_backup_latest.tar.gz.gpg.sha256

# 2. Decrypt & Extract using Podman sub-UID mapping
gpg --batch --decrypt --passphrase-file ~/.backup_passphrase \
    homelab_backup_latest.tar.gz.gpg | podman unshare tar -xzf - -C ~/
```
### Step 3: Execute Playbook Dry-Run
Verify path bindings, template resolution, and user permissions before starting containers:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff -K
```
### Step 4: Full Active Deployment
Deploy volumes, Jinja2 configuration templates, and launch rootless containers and re-establish cron backup schedules:
```bash
ansible-playbook -i inventory.ini site.yml -K
```
---

## 🛠️ 4. Verification & Health Checks
Verify operational status and container health using the following diagnostic commands:

```bash
# 1. Check Podman container status and active port mappings
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Test Pi-hole DNS interception (Host Port 53)
dig @127.0.0.1 -p 53 pi-hole.net

# 3. Test Unbound recursive resolver directly inside container
podman exec -it unbound drill @127.0.0.1 root-servers.net

# 4. Check Pi-hole Web Interface (Host Port 8080)
curl -I http://127.0.0.1:8080/admin/
```
---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
