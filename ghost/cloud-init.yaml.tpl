#cloud-config
# Ghost bootstrap for Aruba Cloud.
# Node.js 22 + nginx + Ghost CLI + Managed MySQL DBaaS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - nginx
  - mysql-client
  - curl
  - certbot
  - python3-certbot-nginx
  - sudo

write_files:
  # DB password stored base64-encoded to avoid shell special-character issues
  - path: /root/ghost-db.b64
    permissions: '0600'
    content: "${db_pass_b64}"

runcmd:
  # ── Node.js 22 via NodeSource ────────────────────────────────────────────────
  - curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  - apt-get install -y nodejs

  # ── Ghost CLI ────────────────────────────────────────────────────────────────
  - npm install -g ghost-cli@latest

  # ── Ghost system user ────────────────────────────────────────────────────────
  - useradd --create-home --shell /bin/bash ghost
  - echo "ghost ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ghost-nopasswd
  - chmod 440 /etc/sudoers.d/ghost-nopasswd

  # ── Ghost directory ──────────────────────────────────────────────────────────
  - mkdir -p /var/www/ghost
  - chown ghost:ghost /var/www/ghost

  # ── nginx config (heredoc so nginx $vars need no Terraform $$ escaping) ──────
  - |
    cat > /etc/nginx/sites-available/ghost.conf << 'NGINX'
    server {
        listen 80;
        server_name ${server_name};
        client_max_body_size 50m;

        location / {
            proxy_pass             http://127.0.0.1:2368;
            proxy_http_version     1.1;
            proxy_set_header       Upgrade $http_upgrade;
            proxy_set_header       Connection 'upgrade';
            proxy_set_header       Host $host;
            proxy_set_header       X-Real-IP $remote_addr;
            proxy_set_header       X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header       X-Forwarded-Proto $scheme;
            proxy_cache_bypass     $http_upgrade;
        }
    }
    NGINX

  # ── nginx ────────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/ghost.conf /etc/nginx/sites-enabled/ghost.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Wait for MySQL (up to 15 minutes) ───────────────────────────────────────
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL did not become ready in 15 minutes"; exit 1; }
      sleep 10
    done

  # ── Install Ghost ─────────────────────────────────────────────────────────────
  - |
    set -euo pipefail
    DB_PASS=$(base64 -d /root/ghost-db.b64)
    sudo -u ghost ghost install \
      --dir /var/www/ghost \
      --db mysql \
      --dbhost "${db_host}" \
      --dbuser "${db_user}" \
      --dbpass "$DB_PASS" \
      --dbname "${db_name}" \
      --url "${site_url}" \
      --process systemd \
      --no-prompt \
      --no-setup-nginx \
      --no-setup-ssl
    rm -f /root/ghost-db.b64

  # ── Optional HTTPS via Let's Encrypt ────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      certbot --nginx \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "admin@$DOMAIN" \
        --redirect \
        $CERTBOT_EAB \
        && echo "HTTPS configured successfully." \
        || echo "WARNING: Certbot failed. Ensure DNS points to this IP and retry."
    fi

  - nginx -t && systemctl reload nginx

final_message: |
  Ghost bootstrap complete.
  Site: ${site_url}
  Admin: ${site_url}/ghost
  Logs: /var/log/cloud-init-output.log
