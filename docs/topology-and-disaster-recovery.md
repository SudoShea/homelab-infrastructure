# 🗺️ Homelab Network Topology & Disaster Recovery Runbook

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<github_username>`, `<primary_storage_node>`, `<cloud_storage_provider>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.8.4
* **Last Updated:** 2026-07-30

---

## 📐 1. Network Topology & Traffic Flow

### Core Architecture Overview
The homelab environment operates on a segmented local network. External web traffic is routed natively via HTTPS to Pi-hole v6, while all host DNS requests are handled locally by Pi-hole chained directly to Unbound for recursive upstream resolution.

```text
[ Local Clients ]
        │
        ├─── Web Admin Requests (Port 80 / 443) ────────► [ Pi-hole Native Web UI (v6) ]
        │
        └─── DNS Queries (Port 53) ──────────────────────► [ Pi-hole DNS Filter ]
                                                               │
                                                               │ (Internal Forward: 127.0.0.1#5335)
                                                               ▼
                                                    [ Unbound Recursive DNS ]
                                                               │
                                                               ▼
                                                   (Direct Root Server Queries)
```
---

## 🔒 2. Container Isolation Boundaries
All service containers run rootless under Podman, managed by the non-privileged system user (ansible_facts['user_id']).

| Service | Container Name | Host Network Port | Sub-System Function | Mount Point / Storage Volume |
| :--- | :--- | :--- | :--- | :--- |
| **Pi-hole** | `pihole` | `53/udp`, `53/tcp`, `80/tcp`, `444/tcp` | DNS Filtering & Ad-blocking | `/var/lib/containers/storage/volumes/etc-pihole`<br>`/var/lib/containers/storage/volumes/etc-dnsmasq.d` |
| **Unbound** | `unbound` | `5335/udp` (Loopback) | Recursive Root DNS Resolver | `/var/lib/containers/storage/volumes/unbound-config` |

---

## 🚨 3. Disaster Recovery Protocol
### Service Level Objectives
* **Recovery Time Objective (RTO):** `< 15 minutes` to restore DNS filtering and web admin access after complete node or storage failure.
* **Recovery Point Objective (RPO):** `< 24 hours` (Nightly automated Restic snapshots).

### Step-by-Step Cold-Boot Recovery Procedure
In the event of a catastrophic host crash, OS reinstall, or drive replacement, follow these steps to restore the full stack:

### Step 1: System Onboarding & Ansible Setup
Ensure the target host is reachable via SSH, Python 3 is installed, and user lingering is active:
```bash
# Clone the repository
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

# Install required Ansible Galaxy collections and external roles
ansible-galaxy install -r requirements.yml
```
### Step 2: Restore Persistent Volume Data via Restic
Locate your Restic repository (local secondary SFTP host `<secondary_storage_node>` or cloud remote `<cloud_storage_provider>`) and restore persistent container volume states:
```bash
# 1. Option A: Use interactive CLI restore tool if previously installed
sudo restic-restore.sh

# 2. Option B: Manual Restic restore execution
sudo restic -r /var/backups/restic \
  --password-file /etc/restic/password \
  restore latest \
  --target / \
  --include /var/lib/containers/storage/volumes
```
### Step 3: Execute Playbook Dry-Run
Verify path bindings, template resolution, and user permissions before launching container services:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff --vault-password-file .vault_pass
```
### Step 4: Full Active Deployment
Deploy host configuration templates, spin up Podman Compose container stacks, and re-establish systemd backup timers (`linux_backup_automation`):
```bash
ansible-playbook -i inventory.ini site.yml --vault-password-file .vault_pass
```
---

## 🛠️ 4. Verification & Health Checks
Verify operational status and container stack health using the following diagnostic commands:

```bash
# 1. Check Podman container status and active port mappings
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Test Pi-hole DNS interception (Host Port 53)
dig @127.0.0.1 -p 53 pi-hole.net

# 3. Test Unbound recursive resolver directly inside container
podman exec -it unbound drill @127.0.0.1 root-servers.net

# 4. Check Pi-hole Web Interface
curl -I [http://127.0.0.1/admin/](http://127.0.0.1/admin/)

# 5. Check Systemd Backup Timer status
systemctl status restic-backup.timer
```
---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
