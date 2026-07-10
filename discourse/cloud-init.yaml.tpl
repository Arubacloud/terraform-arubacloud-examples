#cloud-config
# Discourse community forum bootstrap for Aruba Cloud.
# Uses the official discourse_docker launcher (includes PostgreSQL and Redis).
# Rendered by Terraform templatefile() — do not use this file directly.
#
# WARNING: The bootstrap step builds a Docker image from scratch.
# Expect 20-30 minutes before the forum is accessible.

package_update: true
package_upgrade: true

packages:
  - curl
  - git
  - ca-certificates

write_files:
  # SMTP password stored base64-encoded
  - path: /root/discourse-smtp.b64
    permissions: "0600"
    content: "${smtp_pass_b64}"

  # Discourse app.yml — SMTP password injected at runtime via Python
  - path: /var/discourse/containers/app.yml
    content: |
      templates:
        - "templates/postgres.template.yml"
        - "templates/redis.template.yml"
        - "templates/web.template.yml"
        - "templates/web.ratelimited.template.yml"
      expose:
        - "80:80"
        - "443:443"
      params:
        db_default_text_search_config: "pg_catalog.english"
        db_shared_buffers: "256MB"
      env:
        LANG: en_US.UTF-8
        DISCOURSE_DEFAULT_LOCALE: en
        DISCOURSE_HOSTNAME: "${hostname}"
        DISCOURSE_DEVELOPER_EMAILS: "${admin_email}"
        DISCOURSE_SMTP_ADDRESS: "${smtp_host}"
        DISCOURSE_SMTP_PORT: ${smtp_port}
        DISCOURSE_SMTP_USER_NAME: "${smtp_user}"
        DISCOURSE_SMTP_PASSWORD: "PLACEHOLDER_SMTP_PASS"
        DISCOURSE_SMTP_ENABLE_START_TLS: true
        DISCOURSE_SMTP_AUTHENTICATION: plain
      volumes:
        - volume:
            host: /var/discourse/shared/standalone
            guest: /shared
        - volume:
            host: /var/discourse/shared/standalone/log/var-log
            guest: /var/log
      hooks:
        after_code:
          - exec:
              cd: $home/plugins
              cmd:
                - git clone https://github.com/discourse/docker_manager.git

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
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker

  # ── Clone discourse_docker ────────────────────────────────────────────────────
  - |
    mkdir -p /var/discourse
    git clone https://github.com/discourse/discourse_docker.git /var/discourse

  # ── Inject SMTP password into app.yml ─────────────────────────────────────────
  - |
    python3 - << 'PYEOF'
import base64

smtp_pass = base64.b64decode(open('/root/discourse-smtp.b64').read().strip()).decode()
import os; os.unlink('/root/discourse-smtp.b64')

with open('/var/discourse/containers/app.yml') as f:
    config = f.read()

config = config.replace('PLACEHOLDER_SMTP_PASS', smtp_pass)

with open('/var/discourse/containers/app.yml', 'w') as f:
    f.write(config)
PYEOF

  # ── Bootstrap and start Discourse (20-30 minutes) ────────────────────────────
  - |
    cd /var/discourse
    ./launcher bootstrap app 2>&1 | tee /var/log/discourse-bootstrap.log
    ./launcher start app

final_message: |
  Discourse bootstrap complete (took 20-30 minutes).
  URL: http://${hostname}
  Visit the URL and register with ${admin_email} to activate the admin account.
  Bootstrap log: /var/log/discourse-bootstrap.log
  cloud-init log: /var/log/cloud-init-output.log
