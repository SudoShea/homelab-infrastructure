# 🔒 Native Pi-hole v6 HTTPS & Local Root CA Setup Guide

**Note for Users**: This documentation contains placeholders in angle brackets (e.g., `<username>`, `<pihole_ip>`, `<pihole_domain>`). Replace these placeholders with your actual environment details prior to executing the commands.

* **Repository:** `homelab-infrastructure`
* **Author:** SudoShea
* **Version:** 1.11.0
* **Last Updated:** 2026-08-17

This guide details how to generate a private Root Certificate Authority (CA), issue a local TLS certificate, and natively configure Pi-hole v6 for HTTPS without relying on an external reverse proxy (like Caddy or Nginx).

---

## 📋 Overview & Requirements

* **Web Server:** Pi-hole v6 embedded webserver (Civetweb)
* **TLS File Location:** `/etc/pihole/tls.pem` inside the container
* **Key Requirement:** Civetweb requires an unencrypted private key **placed before** the signed certificate inside a single `tls.pem` file.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Create a Local Root CA (Local Workstation)
On your primary management workstation, create a private Root CA that will sign your homelab certificates:

```bash
mkdir -p ~/homelab-ca && cd ~/homelab-ca

# 1. Generate Root CA Private Key
openssl genrsa -out rootCA.key 4096

# 2. Generate Root CA Certificate (5-year validity)
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1825 \
  -out rootCA.pem -subj "/C=<country>/O=<organisation>/CN=<ca_name>"
```
### Step 2: Trust the Root CA on Client Operating Systems
Fedora / RHEL / CentOS:
```bash
sudo cp rootCA.pem /etc/pki/ca-trust/source/anchors/<ca_name>.pem
sudo update-ca-trust
```
Firefox Browser (Independent Trust Store):
1. Open Firefox -> **Settings** -> **Privacy & Security**.
2. Scroll to **Certificates** -> Click **View Certificates**.
3. Under **Authorities**, click **Import...** and select `rootCA.pem`.
4. Check **"Trust this CA to identify websites"** and click **OK**.

### Step 3: Issue & Format Pi-hole Certificate
1. Create a SAN extension config file (`pihole-ext.cnf`):
```ini
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = <pihole_domain>
IP.1 = <pihole_ip>
```
2. Generate private key, CSR, and sign the certificate:
```bash
# Generate private key
openssl genrsa -out pihole.key 2048

# Create Certificate Signing Request (CSR)
openssl req -new -key pihole.key -out pihole.csr -subj "/C=<country>/O=<organisation>/CN=<pihole_domain>"

# Sign with Root CA (397 days validity)
openssl x509 -req -in pihole.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out pihole.crt -days 397 -sha256 -extfile pihole-ext.cnf

# Convert private key to unencrypted RSA format
openssl rsa -in pihole.key -out pihole-unencrypted.key
```
3. Combine into `tls.pem` (**CRITICAL STEP**):
Civetweb requires the unencrypted key first, followed by the certificate:
```bash
cat pihole-unencrypted.key pihole.crt > tls.pem
```

### Step 4: Deploy to Pi-hole Container
Copy `tls.pem` to your Pi-hole host and ensure correct volume pathing and container user ownership (UID `1000` for standard Pi-hole rootless containers):
```bash
# Copy to remote host
scp tls.pem <username>@<pihole_ip>:/home/<username>/tls.pem

# Move into persistent volume directory, fix ownership (UID 1000), and restart
ssh <username>@<pihole_ip> "sudo mv ~/tls.pem ~/homelab/pihole/etc-pihole/tls.pem && \
  sudo chown 1000:1000 ~/homelab/pihole/etc-pihole/tls.pem && \
  sudo chmod 600 ~/homelab/pihole/etc-pihole/tls.pem && \
  podman restart pihole"
```
---

## ⚙️ Automated Annual Renewal Script

Save the following as `~/homelab-ca/renew-pihole-cert.sh` and schedule it via `crontab`:
```bash
#!/bin/bash
set -e

cd ~/homelab-ca

openssl genrsa -out pihole.key 2048
openssl req -new -key pihole.key -out pihole.csr -subj "/C=<country>/O=<organisation>CN=<pihole_domain>"
openssl x509 -req -in pihole.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out pihole.crt -days 397 -sha256 -extfile pihole-ext.cnf

openssl rsa -in pihole.key -out pihole-unencrypted.key
cat pihole-unencrypted.key pihole.crt > tls.pem

scp tls.pem <username>@<pihole_ip>:/home/<username>/tls.pem
ssh <username>@<pihole_ip> "sudo mv /home/<username>/tls.pem /home/<username>/homelab/pihole/etc-pihole/tls.pem && sudo chown 1000:1000 /home/<username>/homelab/pihole/etc-pihole/tls.pem && sudo chmod 600 /home/<username>/homelab/pihole/etc-pihole/tls.pem && podman restart pihole"

echo "Pi-hole TLS certificate renewed successfully."
```
Schedule annual execution via `crontab -e`:
```plaintext
0 0 1 1 * /home/<username>/homelab-ca/renew-pihole-cert.sh >> /home/<username>/homelab-ca/renewal.log 2>&1
```
---

## 🔍 Verification & Troubleshooting

### 1. Verify Webserver Startup
After restarting the Pi-hole container, verify that Civetweb successfully loaded the TLS bundle:

```bash
podman logs --tail 20 pihole
```
Look for these lines confirming active HTTPS binding:
```plaintext
INFO: Using SSL/TLS certificate file /etc/pihole/tls.pem
INFO: Web server ports:
INFO:   - 0.0.0.0:80 (HTTP, IPv4, OK)
INFO:   - 0.0.0.0:443 (HTTPS, IPv4, OK)
```
### 2. Common Errors
* **`Error initializing SSL context (error code 3.0)`:**
  * **Cause:** Key format/order issue or unreadable file permissions.
  * **Fix:** Ensure `pihole-unencrypted.key` comes before `pihole.crt` in `tls.pem`, and ensure file ownership is set to container user `1000:1000` (`sudo chown 1000:1000 /etc/pihole/tls.pem`).

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
