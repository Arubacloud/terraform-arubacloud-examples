#cloud-config
# Home Assistant bootstrap for Aruba Cloud.
# Runs Home Assistant Container (stable) via Docker Compose.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - ca-certificates
  - gnupg

write_files:
  # Docker Compose file for Home Assistant Container
  - path: /opt/homeassistant/docker-compose.yml
    content: |
      services:
        homeassistant:
          container_name: homeassistant
          image: ghcr.io/home-assistant/home-assistant:stable
          environment:
            TZ: "${timezone}"
          volumes:
            - /opt/homeassistant/config:/config
          network_mode: host
          restart: unless-stopped
          privileged: true

  # systemd service to start HA via Docker Compose on boot
  - path: /etc/systemd/system/homeassistant.service
    content: |
      [Unit]
      Description=Home Assistant
      After=docker.service network-online.target
      Requires=docker.service

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      WorkingDirectory=/opt/homeassistant
      ExecStart=/usr/bin/docker compose up -d
      ExecStop=/usr/bin/docker compose down

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Install Docker ────────────────────────────────────────────────────────────
  - |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # ── Create config directory and start Home Assistant ──────────────────────────
  - mkdir -p /opt/homeassistant/config
  - systemctl enable docker
  - systemctl start docker
  - systemctl daemon-reload
  - systemctl enable homeassistant
  - systemctl start homeassistant

final_message: |
  Home Assistant bootstrap complete.
  URL: http://<IP>:8123  (accessible from admin_cidr only)
  First visit triggers the onboarding wizard — create your admin account there.
  Logs: docker logs homeassistant -f
  cloud-init log: /var/log/cloud-init-output.log
