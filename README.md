# Rootless Podman Homelab Stack 🏠

![Ansible Linting](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)

An Ansible-driven Infrastructure-as-Code repository for provisioning a rootless container stack (Pi-hole, Unbound recursive DNS, and Caddy reverse proxy) managed via Podman.

---

## ⚡ Architecture

* **Rootless Podman:** Serves container workloads without root privilege escalation.
* **Pi-hole (DNS Filter):** Network-wide ad blocking and local DNS resolution.
* **Unbound (Recursive DNS):** Direct root-server DNS resolver (bypasses upstream ISP/third-party tracking).
* **Caddy (Reverse Proxy):** Automated internal TLS and reverse proxying for local services via Jinja2 templating.

---

## 🛠️ Repository Structure
```text
homelab-infrastructure/
├── .github/workflows/lint.yml   # Ansible-lint CI workflow
├── roles/podman_stack/
│   ├── tasks/main.yml           # Core provisioning tasks
│   └── templates/
│       ├── Caddyfile.j2         # Caddy reverse proxy config
│       └── unbound.conf.j2      # Unbound recursive DNS config
├── inventory.ini                # Deployment inventory target
├── CHANGELOG.md                 # Version release history
└── site.yml                     # Playbook entrypoint
```

---

## 🚀 Quick Start

### 1. Clone Repository & Install Prerequisites
Ensure Ansible and the `containers.podman` collection are installed on your control node:
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure

ansible-galaxy collection install containers.podman
```
### 2. Run Dry-Run Check (Safe Mode)
Verify tasks and template rendering against your target system without applying changes:
```bash
ansible-playbook -i inventory.ini site.yml --check --diff
```
### 3. Deploy Stack
Execute the playbook to provision persistent volumes, templates, and rootless containers:
```bash
ansible-playbook -i inventory.ini site.yml
```

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
