# 🗺️ Homelab Network Topology & Disaster Recovery Runbook

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.0.0
* **Last Updated:** 2026-07-24

---

## 📐 1. Network Topology & Traffic Flow

### Core Architecture Overview
The homelab environment operates on a segmented local network. External web traffic is routed via Caddy as an internal reverse proxy, while all host DNS requests are handled locally by Pi-hole chained directly to Unbound for recursive upstream resolution.

```text
[ Local Clients ]
       │
       ├─── HTTP/HTTPS Requests (Port 80/443) ───► [ Caddy Reverse Proxy ]
       │                                                    │
       │                                                    ├──► Pi-hole Web (127.0.0.1:80)
       │                                                    └──► Other Internal Services
       │
       └─── DNS Queries (Port 53) ───────────────► [ Pi-hole DNS Filter ]
                                                            │
                                                            │ (Internal Forward: 127.0.0.1#5335)
                                                            ▼
                                                   [ Unbound Recursive DNS ]
                                                            │
                                                            │ (Direct Root Server Queries)
                                                            ▼
                                                   [ Root DNS Servers ]
```
## 🔒 2. Container Isolation Boundaries
All service containers run rootless under Podman, managed by the non-privileged system user (ansible_facts['user_id']).

| Service | Container Name | Host Network Port | Sub-System Function | Mount Point / Persistence |
| :--- | :--- | :--- | :--- | :--- |
| **Pi-hole** | `pihole` | `53/udp`, `53/tcp`, `80/tcp` | DNS Filtering & Ad-blocking | `~/homelab/pihole/etc-pihole`<br>`~/homelab/pihole/etc-dnsmasq.d` |
| **Unbound** | `unbound` | `5335/udp` (Loopback) | Recursive Root DNS Resolver | `~/homelab/unbound/config` |
| **Caddy** | `caddy` | `80/tcp`, `443/tcp` | Internal TLS & Proxy Routing | `~/homelab/caddy/config`<br>`~/homelab/caddy/data` |

## 🚨 3. Disaster Recovery Protocol
Service Level Objectives

* **Recovery Time Objective (RTO):** `< 15 minutes`
  * Time to restore DNS and core internal web routing after complete node or storage failure.
* **Recovery Point Objective (RPO):** `< 24 hours`
  * Maximum acceptable data age for DNS blocklist/static entry configs.

Step-by-Step Cold-Boot Recovery Procedure

In the event of a catastrophic host crash, OS reinstall, or drive replacement, follow these steps to restore the full stack:
Step 1: System Onboarding & Ansible Setup

Ensure the target host is reachable via SSH, Python 3 is installed, and user lingering is active:
```bash
# Clone the repository
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

# Install required Podman collection
ansible-galaxy collection install containers.podman
```
Step 2: Restore Persistent Volume Data

If restoring from an encrypted backup snapshot (see Backup Runbook), extract the ~/homelab volume directory to the target user's home folder:
```bash
# Example extraction from encrypted archive
gpg -d homelab-backup-latest.tar.gz.gpg | tar -xzf - -C ~/
```
Step 3: Execute Playbook Dry-Run

Verify path bindings, template resolution, and user permissions before starting containers:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff
```
Step 4: Full Active Deployment

Deploy volumes, Jinja2 configuration templates, and launch rootless containers:
```bash
ansible-playbook -i inventory.ini site.yml
```

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
