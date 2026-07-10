#cloud-config
# Sonatype Nexus Repository OSS for Aruba Cloud.
# Deployed via Docker with persistent storage on /opt/nexus-data.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# JVM startup takes 2-3 minutes. The auto-generated admin password is written
# to /nexus-data/admin.password and removed after the first login.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

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

  # ── Prepare persistent data directory (Nexus runs as UID 200) ─────────────────
  - mkdir -p /opt/nexus-data
  - chown -R 200:200 /opt/nexus-data

  # ── Start Nexus Repository ────────────────────────────────────────────────────
  - |
    docker run -d \
      --name nexus \
      --restart unless-stopped \
      -p 8081:8081 \
      %{ if enable_docker_registry ~}
      -p 8082:8082 \
      %{ endif ~}
      -v /opt/nexus-data:/nexus-data \
      sonatype/nexus3:${nexus_version}

  # ── Wait for Nexus to be ready (JVM startup: 2-3 minutes) ─────────────────────
  - |
    echo "Waiting for Nexus to start (2-3 minutes)..."
    for i in $(seq 1 72); do
      HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8081)
      [ "$HTTP_CODE" = "200" ] && { echo "Nexus ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  Nexus Repository bootstrap complete.
  Web UI: http://<IP>:8081
  Admin username: admin
  Admin password: docker exec nexus cat /nexus-data/admin.password
  Logs: docker logs nexus -f
  cloud-init log: /var/log/cloud-init-output.log
