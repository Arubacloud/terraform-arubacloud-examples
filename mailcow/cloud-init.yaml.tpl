#cloud-config
# Mailcow dockerized email server for Aruba Cloud.
# Installs Docker CE, clones mailcow-dockerized, generates config, and starts all services.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# DNS MUST point to the VM public IP BEFORE running terraform apply
# (Let's Encrypt requires DNS to resolve for certificate issuance).
# Bootstrap takes 5-10 minutes.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg
  - git

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
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - usermod -aG docker ubuntu

  # ── Clone mailcow-dockerized ──────────────────────────────────────────────────
  - git clone --branch "${mailcow_branch}" https://github.com/mailcow/mailcow-dockerized /opt/mailcow-dockerized

  # ── Generate mailcow configuration ───────────────────────────────────────────
  - |
    cd /opt/mailcow-dockerized
    MAILCOW_HOSTNAME="${mail_hostname}" MAILCOW_TZ="Europe/Rome" \
      MAILCOW_BRANCH="${mailcow_branch}" ./generate_config.sh

  # ── Pull images and start all services ───────────────────────────────────────
  - cd /opt/mailcow-dockerized && docker compose pull --quiet
  - cd /opt/mailcow-dockerized && docker compose up -d

final_message: |
  Mailcow bootstrap complete (may take 5-10 minutes).
  Web UI:  https://${mail_hostname}
  Admin:   admin / moohoo  — change on first login!
  Docs:    https://docs.mailcow.email/
  Logs:    cd /opt/mailcow-dockerized && docker compose logs -f
  cloud-init log: /var/log/cloud-init-output.log
