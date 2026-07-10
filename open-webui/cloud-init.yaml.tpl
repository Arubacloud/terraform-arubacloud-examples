#cloud-config
# Open WebUI bootstrap for Aruba Cloud.
# Deployed via Docker; forwards to Ollama or OpenAI-compatible backends.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg
  - nginx

write_files:
  # Credentials stored base64-encoded
  - path: /root/webui-secret.b64
    permissions: "0600"
    content: "${secret_key_b64}"

  - path: /root/openai-key.b64
    permissions: "0600"
    content: "${openai_key_b64}"

  # nginx reverse proxy
  - path: /etc/nginx/sites-available/open-webui
    content: |
      server {
          listen 80;
          server_name _;
          client_max_body_size 64M;

          location / {
              proxy_pass         http://127.0.0.1:3000;
              proxy_http_version 1.1;
              proxy_set_header   Upgrade $http_upgrade;
              proxy_set_header   Connection "upgrade";
              proxy_set_header   Host $host;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Proto $scheme;
              proxy_read_timeout 300s;
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

  # ── Start Open WebUI ──────────────────────────────────────────────────────────
  - |
    SECRET_KEY=$(base64 -d /root/webui-secret.b64)
    OPENAI_KEY=$(base64 -d /root/openai-key.b64)
    rm -f /root/webui-secret.b64 /root/openai-key.b64

    OLLAMA_ARG=""
    if [ -n "${ollama_base_url}" ]; then
      OLLAMA_ARG="--env OLLAMA_BASE_URL=${ollama_base_url}"
    fi

    OPENAI_ARG=""
    if [ -n "$OPENAI_KEY" ]; then
      OPENAI_ARG="--env OPENAI_API_KEY=$OPENAI_KEY"
    fi

    if [ -z "$SECRET_KEY" ]; then
      SECRET_KEY=$(openssl rand -hex 32)
    fi

    docker run -d \
      --name open-webui \
      --restart unless-stopped \
      --env WEBUI_SECRET_KEY="$SECRET_KEY" \
      --env WEBUI_AUTH=true \
      $OLLAMA_ARG \
      $OPENAI_ARG \
      -v open-webui:/app/backend/data \
      -p 127.0.0.1:3000:8080 \
      ghcr.io/open-webui/open-webui:${open_webui_version}

  # ── Configure nginx ───────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/open-webui /etc/nginx/sites-enabled/open-webui
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

final_message: |
  Open WebUI bootstrap complete.
  URL: http://<IP>
  First user to register becomes the admin.
  Container logs: docker logs open-webui -f
  cloud-init log: /var/log/cloud-init-output.log
