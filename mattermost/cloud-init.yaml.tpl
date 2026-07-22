#cloud-config
# Mattermost Team Edition bootstrap for Aruba Cloud.
# Mattermost binary + nginx reverse proxy + Managed MySQL 8.0 DBaaS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - nginx
  - curl
  - certbot
  - python3-certbot-nginx
  - mysql-client

write_files:
  # DB password stored base64-encoded to avoid shell special-character issues
  - path: /root/mm-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"

  # nginx reverse proxy for Mattermost
  - path: /etc/nginx/sites-available/mattermost.conf
    content: |
      upstream mattermost {
          server 127.0.0.1:8065;
          keepalive 32;
      }

      server {
          listen 80;
          server_name ${server_name};

          location ~ /api/v[0-9]+/(users/)?websocket$$ {
              proxy_pass              http://mattermost;
              proxy_http_version      1.1;
              proxy_set_header        Upgrade $$http_upgrade;
              proxy_set_header        Connection "Upgrade";
              proxy_set_header        Host $$host;
              proxy_set_header        X-Real-IP $$remote_addr;
              proxy_set_header        X-Forwarded-For $$proxy_add_x_forwarded_for;
              proxy_set_header        X-Forwarded-Proto $$scheme;
              proxy_set_header        X-Frame-Options SAMEORIGIN;
              proxy_read_timeout      90s;
          }

          location / {
              proxy_pass              http://mattermost;
              proxy_http_version      1.1;
              proxy_set_header        Connection "";
              proxy_set_header        Host $$host;
              proxy_set_header        X-Real-IP $$remote_addr;
              proxy_set_header        X-Forwarded-For $$proxy_add_x_forwarded_for;
              proxy_set_header        X-Forwarded-Proto $$scheme;
              proxy_set_header        X-Frame-Options SAMEORIGIN;
              proxy_read_timeout      90s;
              client_max_body_size    50m;
          }
      }

  # Mattermost systemd unit
  - path: /etc/systemd/system/mattermost.service
    content: |
      [Unit]
      Description=Mattermost
      After=network.target

      [Service]
      Type=notify
      ExecStart=/opt/mattermost/bin/mattermost
      Restart=on-failure
      RestartSec=10
      WorkingDirectory=/opt/mattermost
      User=mattermost
      Group=mattermost
      LimitNOFILE=49152

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── System user ───────────────────────────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false mattermost

  # ── Download and install Mattermost ──────────────────────────────────────────
  - |
    MM_VERSION="${mattermost_version}"
    curl -sSfL \
      "https://releases.mattermost.com/$MM_VERSION/mattermost-team-$MM_VERSION-linux-amd64.tar.gz" \
      | tar -xz -C /opt
    chown -R mattermost:mattermost /opt/mattermost
    mkdir -p /opt/mattermost/data
    chown mattermost:mattermost /opt/mattermost/data

  # ── Wait for MySQL (up to 15 minutes) ────────────────────────────────────────
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL did not become ready in 15 minutes"; exit 1; }
      sleep 10
    done

  # ── Configure Mattermost via environment file ─────────────────────────────────
  - |
    DB_PASS=$(base64 -d /root/mm-db.b64)
    DSN="${db_user}:$DB_PASS@tcp(${db_host}:3306)/${db_name}?charset=utf8mb4,utf8&readTimeout=30s&writeTimeout=30s"
    mkdir -p /etc/mattermost
    cat > /etc/mattermost/env <<EOF
    MM_SERVICESETTINGS_SITEURL=${site_url}
    MM_SQLSETTINGS_DRIVERNAME=mysql
    MM_SQLSETTINGS_DATASOURCE=$DSN
    MM_FILESETTINGS_DIRECTORY=/opt/mattermost/data
    MM_LOGSETTINGS_ENABLECONSOLE=true
    MM_LOGSETTINGS_CONSOLELEVEL=INFO
    EOF
    chmod 600 /etc/mattermost/env
    rm -f /root/mm-db.b64

  # ── Inject EnvironmentFile into systemd unit ──────────────────────────────────
  - |
    sed -i '/\[Service\]/a EnvironmentFile=/etc/mattermost/env' \
      /etc/systemd/system/mattermost.service

  # ── Start Mattermost ─────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now mattermost

  # ── nginx setup ───────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/mattermost.conf /etc/nginx/sites-enabled/mattermost.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Optional HTTPS via Let's Encrypt ─────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      for i in $(seq 1 24); do
        curl -sf http://127.0.0.1:8065/api/v4/system/ping >/dev/null && break
        sleep 5
      done
      certbot --nginx \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "admin@$DOMAIN" \
        --redirect \
        $CERTBOT_EAB \
        && echo "HTTPS configured." \
        || echo "WARNING: Certbot failed. Ensure DNS points to this IP and retry."
    fi

  - nginx -t && systemctl reload nginx

final_message: |
  Mattermost bootstrap complete.
  URL: ${site_url}
  First user to register becomes System Admin.
  Logs: /var/log/cloud-init-output.log
  Mattermost logs: journalctl -u mattermost -f
