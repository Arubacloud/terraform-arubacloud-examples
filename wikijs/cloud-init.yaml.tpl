#cloud-config
# Wiki.js knowledge base for Aruba Cloud.
# Deployed via Docker with Managed MySQL 8.0 as the database backend.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# Bootstrap takes 2-3 minutes. Complete the setup wizard on first access.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  - path: /root/wikijs-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"

runcmd:
  # ── Install Docker CE ─────────────────────────────────────────────────────────
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - usermod -aG docker ubuntu

  # ── Start Wiki.js container ───────────────────────────────────────────────────
  - |
    DB_PASS=$(base64 -d /root/wikijs-db.b64)
    rm -f /root/wikijs-db.b64
    docker run -d \
      --name wikijs \
      --restart unless-stopped \
      -e DB_TYPE=mysql \
      -e DB_HOST="${db_host}" \
      -e DB_PORT=3306 \
      -e DB_NAME="${db_name}" \
      -e DB_USER="${db_user}" \
      -e DB_PASS="$DB_PASS" \
      -p 3000:3000 \
      ghcr.io/requarks/wiki:${wikijs_version}

  # ── Wait for Wiki.js to be ready ──────────────────────────────────────────────
  - |
    echo "Waiting for Wiki.js..."
    for i in $(seq 1 36); do
      HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:3000)
      [ "$HTTP_CODE" = "200" ] && { echo "Wiki.js ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  Wiki.js bootstrap complete.
  Web UI: http://<IP>:3000
  Complete the setup wizard on first access to create the admin account.
  Logs: docker logs wikijs -f
  cloud-init log: /var/log/cloud-init-output.log
