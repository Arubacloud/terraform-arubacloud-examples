#cloud-config
# Gitea bootstrap for Aruba Cloud.
# Gitea binary + nginx reverse proxy + optional Managed MySQL DBaaS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - git
  - nginx
  - curl
  - certbot
  - python3-certbot-nginx
  - sqlite3

write_files:
  # Gitea app.ini — pre-configured so the web installer is bypassed
  - path: /etc/gitea/app.ini
    owner: "root:git"
    permissions: "0640"
    content: |
      APP_NAME = Gitea
      RUN_USER = git
      RUN_MODE = prod
      WORK_PATH = /var/lib/gitea

      [server]
      DOMAIN           = ${ssh_host}
      ROOT_URL         = ${base_url}/
      HTTP_ADDR        = 127.0.0.1
      HTTP_PORT        = 3000
      SSH_DOMAIN       = ${ssh_host}
      SSH_PORT         = 2222
      START_SSH_SERVER = true
      SSH_LISTEN_HOST  = 0.0.0.0
      SSH_LISTEN_PORT  = 2222

      [database]
%{ if enable_mysql }
      DB_TYPE  = mysql
      HOST     = ${db_host}:3306
      NAME     = ${db_name}
      USER     = ${db_user}
      PASSWD   = __DB_PASS__
      SSL_MODE = disable
%{ else }
      DB_TYPE = sqlite3
      PATH    = /var/lib/gitea/data/gitea.db
%{ endif }

      [security]
      INSTALL_LOCK   = true
      SECRET_KEY     = __SECRET_KEY__
      INTERNAL_TOKEN = __INTERNAL_TOKEN__

      [service]
      DISABLE_REGISTRATION       = false
      REQUIRE_SIGNIN_VIEW        = false
      DEFAULT_KEEP_EMAIL_PRIVATE = false

      [log]
      MODE      = console
      LEVEL     = info
      ROOT_PATH = /var/lib/gitea/log

  # nginx reverse proxy — routes HTTP traffic to Gitea on port 3000
  - path: /etc/nginx/sites-available/gitea.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};
          client_max_body_size 100m;

          location / {
              proxy_pass         http://127.0.0.1:3000;
              proxy_http_version 1.1;
              proxy_set_header   Upgrade $$http_upgrade;
              proxy_set_header   Connection 'upgrade';
              proxy_set_header   Host $$host;
              proxy_set_header   X-Real-IP $$remote_addr;
              proxy_set_header   X-Forwarded-For $$proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Proto $$scheme;
          }
      }

  # Gitea systemd unit
  - path: /etc/systemd/system/gitea.service
    content: |
      [Unit]
      Description=Gitea
      After=network.target

      [Service]
      User=git
      Group=git
      WorkingDirectory=/var/lib/gitea
      ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
      Restart=on-failure
      RestartSec=10
      Environment=HOME=/home/git USER=git GITEA_WORK_DIR=/var/lib/gitea

      [Install]
      WantedBy=multi-user.target

%{ if enable_mysql }
  # DB password stored base64-encoded to avoid shell special-character issues
  - path: /root/gitea-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"
%{ endif }

runcmd:
  # ── Create git system user ────────────────────────────────────────────────────
  - useradd --system --create-home --home-dir /home/git --shell /bin/bash git

  # ── Create Gitea directories ──────────────────────────────────────────────────
  - mkdir -p /var/lib/gitea/{data,log,repos,custom} /etc/gitea
  - chown -R git:git /var/lib/gitea /etc/gitea
  - chmod 750 /etc/gitea

  # ── Download Gitea binary ─────────────────────────────────────────────────────
  - |
    GITEA_VERSION="${gitea_version}"
    ARCH=$(dpkg --print-architecture)
    [ "$ARCH" = "arm64" ] && BIN_ARCH="arm64" || BIN_ARCH="amd64"
    curl -sSfL \
      "https://dl.gitea.com/gitea/$GITEA_VERSION/gitea-$GITEA_VERSION-linux-$BIN_ARCH" \
      -o /usr/local/bin/gitea
    chmod +x /usr/local/bin/gitea

  # ── Generate secrets ─────────────────────────────────────────────────────────
  - |
    SECRET_KEY=$(openssl rand -hex 32)
    INTERNAL_TOKEN=$(openssl rand -hex 64)
    sed -i \
      "s|__SECRET_KEY__|$SECRET_KEY|;s|__INTERNAL_TOKEN__|$INTERNAL_TOKEN|" \
      /etc/gitea/app.ini

%{ if enable_mysql }
  # ── Wait for MySQL (up to 15 minutes) ────────────────────────────────────────
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL did not become ready in 15 minutes"; exit 1; }
      sleep 10
    done

  # ── Inject MySQL password ─────────────────────────────────────────────────────
  - |
    DB_PASS=$(base64 -d /root/gitea-db.b64)
    sed -i "s|__DB_PASS__|$DB_PASS|" /etc/gitea/app.ini
    rm -f /root/gitea-db.b64

%{ endif }
  # ── Fix ownership after secret injection ─────────────────────────────────────
  - chown git:git /etc/gitea/app.ini

  # ── nginx setup ───────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/gitea.conf /etc/nginx/sites-enabled/gitea.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Start Gitea ───────────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now gitea

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
        curl -sf http://127.0.0.1:3000 >/dev/null && break
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
  Gitea bootstrap complete.
  Web: ${base_url}
  Git SSH: ssh://git@<IP>:2222/<owner>/<repo>.git
  First user to register becomes admin.
  Logs: /var/log/cloud-init-output.log
