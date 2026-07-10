#cloud-config
# OpenClaw bootstrap for Aruba Cloud.
# Self-hosted personal AI agent with persistent memory and messaging integrations.
# Deployed via Docker using the official OpenClaw image.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg
  - nginx

write_files:
  # API keys stored base64-encoded
  - path: /root/openai-key.b64
    permissions: "0600"
    content: "${openai_key_b64}"

  - path: /root/anthropic-key.b64
    permissions: "0600"
    content: "${anthropic_key_b64}"

  # nginx reverse proxy
  - path: /etc/nginx/sites-available/openclaw
    content: |
      server {
          listen 3000;
          server_name _;
          client_max_body_size 32M;

          location / {
              proxy_pass         http://127.0.0.1:3001;
              proxy_http_version 1.1;
              proxy_set_header   Upgrade $http_upgrade;
              proxy_set_header   Connection "upgrade";
              proxy_set_header   Host $host;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Proto $scheme;
          }
      }

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

  # ── Start OpenClaw ────────────────────────────────────────────────────────────
  - |
    OPENAI_KEY=$(base64 -d /root/openai-key.b64)
    ANTHROPIC_KEY=$(base64 -d /root/anthropic-key.b64)
    rm -f /root/openai-key.b64 /root/anthropic-key.b64

    mkdir -p /opt/openclaw/data

    OPENAI_ARG=""
    [ -n "$OPENAI_KEY" ] && OPENAI_ARG="--env OPENAI_API_KEY=$OPENAI_KEY"

    ANTHROPIC_ARG=""
    [ -n "$ANTHROPIC_KEY" ] && ANTHROPIC_ARG="--env ANTHROPIC_API_KEY=$ANTHROPIC_KEY"

    docker run -d \
      --name openclaw \
      --restart unless-stopped \
      $OPENAI_ARG \
      $ANTHROPIC_ARG \
      -v /opt/openclaw/data:/app/data \
      -p 127.0.0.1:3001:3000 \
      ghcr.io/openclaw/openclaw:latest

  # ── Configure nginx ───────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

final_message: |
  OpenClaw bootstrap complete.
  URL: http://<IP>:3000
  Container logs: docker logs openclaw -f
  cloud-init log: /var/log/cloud-init-output.log
