#cloud-config
# Keycloak bootstrap for Aruba Cloud.
# Keycloak Quarkus distribution + local PostgreSQL + nginx reverse proxy.
# Java 21 required. Managed MySQL is NOT officially supported by Keycloak.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - nginx
  - certbot
  - python3-certbot-nginx
  - postgresql
  - postgresql-client
  - openjdk-21-jdk-headless

write_files:
  # Credentials (base64-encoded, removed after use)
  - path: /root/kc-secrets.b64
    permissions: "0600"
    content: "${kc_admin_pass_b64} ${db_pass_b64}"

  # Keycloak systemd unit — reads /etc/keycloak/env for admin bootstrap credentials
  - path: /etc/systemd/system/keycloak.service
    content: |
      [Unit]
      Description=Keycloak
      After=network.target postgresql.service

      [Service]
      User=keycloak
      Group=keycloak
      WorkingDirectory=/opt/keycloak
      EnvironmentFile=-/etc/keycloak/env
      ExecStart=/opt/keycloak/bin/kc.sh start --optimized
      Restart=on-failure
      RestartSec=10
      StandardOutput=journal
      StandardError=journal

      [Install]
      WantedBy=multi-user.target

  # nginx reverse proxy for Keycloak
  - path: /etc/nginx/sites-available/keycloak.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              proxy_pass              http://127.0.0.1:8080;
              proxy_http_version      1.1;
              proxy_set_header        Upgrade $$http_upgrade;
              proxy_set_header        Connection 'upgrade';
              proxy_set_header        Host $$host;
              proxy_set_header        X-Real-IP $$remote_addr;
              proxy_set_header        X-Forwarded-For $$proxy_add_x_forwarded_for;
              proxy_set_header        X-Forwarded-Proto $$scheme;
              proxy_set_header        X-Forwarded-Host $$host;
              proxy_set_header        X-Forwarded-Port $$server_port;
              proxy_buffer_size       128k;
              proxy_buffers           4 256k;
              proxy_busy_buffers_size 256k;
          }
      }

runcmd:
  # ── Decode secrets ────────────────────────────────────────────────────────────
  - |
    SECRETS=$(cat /root/kc-secrets.b64)
    KC_ADMIN_PASS=$(echo "$SECRETS" | awk '{print $1}' | base64 -d)
    DB_PASS=$(echo "$SECRETS" | awk '{print $2}' | base64 -d)
    rm -f /root/kc-secrets.b64

    # ── PostgreSQL setup ──────────────────────────────────────────────────────
    systemctl enable --now postgresql
    sudo -u postgres psql -c "CREATE USER keycloak WITH PASSWORD '$DB_PASS';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE keycloak OWNER keycloak;"       2>/dev/null || true

    # ── Download and install Keycloak ─────────────────────────────────────────
    KC_VERSION="${keycloak_version}"
    curl -sSfL \
      "https://github.com/keycloak/keycloak/releases/download/$KC_VERSION/keycloak-$KC_VERSION.tar.gz" \
      | tar -xz -C /opt
    mv /opt/keycloak-$KC_VERSION /opt/keycloak

    # ── Write keycloak.conf ───────────────────────────────────────────────────
    mkdir -p /opt/keycloak/conf
    cat > /opt/keycloak/conf/keycloak.conf <<EOF
    db=postgres
    db-url=jdbc:postgresql://localhost/keycloak
    db-username=keycloak
    db-password=$DB_PASS
    hostname=${kc_hostname}
    hostname-strict=false
    hostname-backchannel-dynamic=true
    http-enabled=true
    proxy-headers=xforwarded
    health-enabled=true
    metrics-enabled=true
    EOF

    # ── Write admin bootstrap env file (read by systemd on first start) ───────
    mkdir -p /etc/keycloak
    printf 'KEYCLOAK_ADMIN=%s\nKEYCLOAK_ADMIN_PASSWORD=%s\n' \
      "${kc_admin}" "$KC_ADMIN_PASS" \
      > /etc/keycloak/env
    chmod 600 /etc/keycloak/env

    # ── System user and permissions ───────────────────────────────────────────
    useradd --system --no-create-home --shell /bin/false keycloak 2>/dev/null || true
    chown -R keycloak:keycloak /opt/keycloak /etc/keycloak
    chmod -R o-rwx /opt/keycloak/conf /etc/keycloak

    # ── Build Keycloak for production mode ────────────────────────────────────
    sudo -u keycloak /opt/keycloak/bin/kc.sh build --db=postgres --http-enabled=true

  # ── Start Keycloak ────────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now keycloak

  # ── Wait for Keycloak to be ready (admin user is created on first start) ──────
  - |
    echo "Waiting for Keycloak to be ready ..."
    for i in $(seq 1 60); do
      curl -sf http://localhost:8080/health/ready >/dev/null && { echo "Keycloak ready."; break; }
      [ "$i" = "60" ] && { echo "ERROR: Keycloak did not start in 5 minutes"; exit 1; }
      sleep 5
    done

  # ── nginx ─────────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/keycloak.conf /etc/nginx/sites-enabled/keycloak.conf
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
  Keycloak bootstrap complete.
  Admin console: ${base_url}/admin
  Admin user: ${kc_admin}
  Logs: /var/log/cloud-init-output.log
  Keycloak logs: journalctl -u keycloak -f
