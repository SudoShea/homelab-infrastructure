# Rootless Podman Homelab Stack 🏠

![Ansible Linting](https://github.com/SudoShea/homelab-infrastructure/actions/workflows/lint.yml/badge.svg)

An Ansible-driven Infrastructure-as-Code repository for provisioning a rootless container stack (Pi-hole, Unbound recursive DNS, and Caddy reverse proxy) managed via Podman.

---

## ⚡ Architecture

* **Rootless Podman:** Serves container workloads without root privilege escalation.
* **Pi-hole (DNS Filter):** Network-wide ad blocking and local DNS resolution.
* **Unbound (Recursive DNS):** Direct root-server DNS resolver (bypasses upstream ISP/third-party tracking).
* **Caddy (Reverse Proxy):** Automated internal TLS and reverse proxying for local services.

---

## 🚀 Quick Start

### 1. Clone repository
```bash
git clone https://github.com/SudoShea/homelab-infrastructure.git
cd homelab-infrastructure
```
### 2. Run Playbook
```bash
ansible-playbook -i "localhost," -c local site.yml
```

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
