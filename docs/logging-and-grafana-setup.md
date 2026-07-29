# 📊 Centralised Logging & Grafana HTTPS Setup Guide

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<username>`, `<logging_server_ip>`, `<grafana_domain>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.8.2
* **Last Updated:** 2026-07-29

This guide details the architecture, deployment, and Root CA TLS configuration for the centralised logging stack (Vector $\rightarrow$ Loki $\rightarrow$ Grafana) deployed across the homelab infrastructure.

---

## 📋 Stack Architecture

The logging pipeline captures systemd journal logs, container logs, and authentication events across all nodes and centralises them for visual inspection in Grafana:

```text
[ Homelab Host ] ---> Vector (Log Shipper) ---> [ Logging Host (<logging_server_ip>) ]
                                                            │
                                                            ▼
                                                   Loki (Engine:3100)
                                                            │
                                                            ▼
                                                Grafana (UI:3000 HTTPS)
```
* **Vector** (`roles/logging_shipper`): Runs natively on all nodes, collects `journald` logs, and forwards them to Loki over HTTP/TCP.
* **Loki** (`roles/logging_server`): Runs as a rootless Podman container on `<logging_server_ip>`, indexing and storing log streams.
* **Grafana** (`roles/logging_server`): Visualizes logs via pre-provisioned dashboards over HTTPS secured by the local Root CA.

---

## 🔒 TLS Certificate Configuration (Grafana)

Grafana uses native TLS encryption on port 3000 signed by the homelab Root CA (rootCA.pem).

### Step 1: Issue Certificate on Management Workstation
Navigate to your local Root CA directory (`~/homelab-ca/`) on your primary workstation:
```bash
cd ~/homelab-ca

# 1. Create SAN Extension Config File
cat << 'EOF' > grafana-ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = <grafana_domain>
IP.1 = <logging_server_ip>
EOF

# 2. Generate Private Key and Certificate Signing Request (CSR)
openssl genrsa -out grafana.key 2048
openssl req -new -key grafana.key -out grafana.csr -subj "/O=<organisation>/CN=<grafana_domain>"

# 3. Sign Certificate with Homelab Root CA (397 days validity)
openssl x509 -req -in grafana.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out grafana.crt -days 397 -sha256 -extfile grafana-ext.cnf
```
### Step 2: Deploy Certificates to Logging Host
Copy `grafana.crt` and `grafana.key` to the target host and set `0644` permissions so the unprivileged Grafana container user (UID `472`) can read them:
```bash
# Copy certificate files to logging server host
scp grafana.crt grafana.key <username>@<logging_server_ip>:/home/<username>/homelab/grafana/certs/

# Fix permissions for container execution
ssh <username>@<logging_server_ip> "chmod 644 /home/<username>/homelab/grafana/certs/grafana.*"
```
---

## ⚙️ Podman & Ansible Container Configuration

The `roles/logging_server` Ansible role configures the Grafana Podman container with native TLS enabled:
```yaml
- name: Deploy Grafana dashboard container
  containers.podman.podman_container:
    name: grafana
    image: docker.io/grafana/grafana:latest
    state: started
    recreate: true
    restart_policy: always
    network: host
    env:
      GF_SERVER_PROTOCOL: "https"
      GF_SERVER_CERT_FILE: "/etc/grafana/certs/grafana.crt"
      GF_SERVER_CERT_KEY: "/etc/grafana/certs/grafana.key"
      GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: "/var/lib/grafana/dashboards/systemd-podman-logs.json"
    volumes:
      - "{{ ansible_facts['user_dir'] }}/homelab/grafana/data:/var/lib/grafana:z,U"
      - "{{ ansible_facts['user_dir'] }}/homelab/grafana/certs:/etc/grafana/certs:z"
      - "{{ ansible_facts['user_dir'] }}/homelab/grafana/provisioning:/etc/grafana/provisioning:z"
      - "{{ ansible_facts['user_dir'] }}/homelab/grafana/dashboards:/var/lib/grafana/dashboards:z"
```
---

## 🔍 Verification & Access

1. **DNS Resolution**: Ensure local DNS or `/etc/hosts` on client devices maps `<grafana_domain>` to `<logging_server_ip>`.
2. **Access Web UI**: Navigate to `https://<grafana_domain>:3000` in your web browser.
3. **Verify TLS Trust**: Confirm that the browser displays a valid, trusted connection (issued by your `<ca_name>`).
4. **Log Flow Verification**: Open the pre-provisioned **Systemd & Podman Logs** dashboard to verify incoming streams from Loki and Vector.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
