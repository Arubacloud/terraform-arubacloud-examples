#cloud-config
# Vaultwarden (Bitwarden-compatible server) bootstrap for Aruba Cloud.
# Deployed via Docker for the most up-to-date and supported installation method.

package_update: true
package_upgrade: true
packages:
  - ca-certificates
  - curl
  - gnupg
  - nginx
  - certbot
  - python3-certbot-nginx

write_files:
  - path: /etc/nginx/sites-available/vaultwarden
    content: |
      server {
          listen 80;
          server_name _;
          client_max_body_size 128M;

          location / {
              proxy_pass         http://127.0.0.1:8080;
              proxy_set_header   Host $host;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Proto $scheme;
          }
          location /notifications/hub {
              proxy_pass         http://127.0.0.1:3012;
              proxy_http_version 1.1;
              proxy_set_header   Upgrade $http_upgrade;
              proxy_set_header   Connection "upgrade";
          }
      }

runcmd:
  # Install Docker CE
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

  # Create persistent data directory
  - mkdir -p /opt/vaultwarden/data
  - chown -R 1000:1000 /opt/vaultwarden/data

  # Start Vaultwarden container
  - |
    ADMIN_TOKEN_ARG=""
    if [ -n "${admin_token}" ]; then
      ADMIN_TOKEN_ARG="--env ADMIN_TOKEN=${admin_token}"
    fi
    docker run -d \
      --name vaultwarden \
      --restart unless-stopped \
      --env WEBSOCKET_ENABLED=true \
      --env DOMAIN="${site_url}" \
      $ADMIN_TOKEN_ARG \
      -v /opt/vaultwarden/data:/data \
      -p 127.0.0.1:8080:80 \
      -p 127.0.0.1:3012:3012 \
      vaultwarden/server:${vaultwarden_version}

  # Configure and enable nginx reverse proxy
  - ln -sf /etc/nginx/sites-available/vaultwarden /etc/nginx/sites-enabled/vaultwarden
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # Optional: provision TLS certificate with Certbot
  - |
    DOMAIN="${domain}"
    if [ -n "$DOMAIN" ]; then
      certbot --nginx -d "$DOMAIN" \
        --non-interactive --agree-tos \
        -m "${admin_email}" \
        --redirect \
        && echo "HTTPS configured for $DOMAIN" \
        || echo "WARNING: Certbot failed — verify DNS points to this IP"
    fi

  - systemctl reload nginx

final_message: "Vaultwarden is running at ${site_url}"
