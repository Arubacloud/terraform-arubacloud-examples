#cloud-config
# Apache Superset bootstrap for Aruba Cloud.
# Native pip install + gunicorn + MySQL DBaaS metadata DB + nginx + optional ACME HTTPS.
# Rendered by Terraform templatefile() — do not use this file directly.
# NOTE: Bootstrap takes 20–30 minutes — Superset has many Python dependencies.

package_update: false

write_files:
  # ── Secrets (base64-encoded) ──────────────────────────────────────────────
  - path: /root/db-pass.b64
    permissions: "0600"
    content: "${db_password_b64}"

  - path: /root/admin-pass.b64
    permissions: "0600"
    content: "${admin_password_b64}"

  # ── Python setup: writes /etc/superset/superset_config.py and superset.env ─
  - path: /root/setup-superset.py
    permissions: "0700"
    content: |
      import base64, pathlib, secrets, urllib.parse

      db_pass     = base64.b64decode(pathlib.Path('/root/db-pass.b64').read_text().strip()).decode()
      db_pass_url = urllib.parse.quote(db_pass, safe='')
      secret_key  = secrets.token_hex(32)

      pathlib.Path('/etc/superset').mkdir(parents=True, exist_ok=True)

      cfg = (
          "from flask_appbuilder.security.manager import AUTH_DB\n"
          f"SQLALCHEMY_DATABASE_URI = 'mysql+mysqldb://superset:{db_pass_url}@${db_host}:3306/${db_name}'\n"
          f"SECRET_KEY = '{secret_key}'\n"
          "DATA_DIR = '/var/lib/superset'\n"
          "ENABLE_PROXY_FIX = True\n"
          "WTF_CSRF_ENABLED = True\n"
          "SESSION_COOKIE_HTTPONLY = True\n"
          "SESSION_COOKIE_SECURE = False\n"
          "AUTH_TYPE = AUTH_DB\n"
      )
      pathlib.Path('/etc/superset/superset_config.py').write_text(cfg)

      env_lines = [
          "SUPERSET_CONFIG_PATH=/etc/superset/superset_config.py",
          "FLASK_APP=superset",
          "PYTHONPATH=/etc/superset:$PYTHONPATH",
      ]
      pathlib.Path('/etc/superset/superset.env').write_text('\n'.join(env_lines) + '\n')

      pathlib.Path('/root/setup-superset.py').unlink()

  # ── nginx reverse proxy ───────────────────────────────────────────────────
  - path: /etc/nginx/sites-available/superset.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              proxy_pass         http://127.0.0.1:8088;
              proxy_http_version 1.1;
              proxy_set_header   Host              $${host};
              proxy_set_header   X-Real-IP         $${remote_addr};
              proxy_set_header   X-Forwarded-For   $${proxy_add_x_forwarded_for};
              proxy_set_header   X-Forwarded-Proto $${scheme};
              proxy_read_timeout 300;
              client_max_body_size 50M;
          }
      }

  # ── systemd: superset ─────────────────────────────────────────────────────
  - path: /etc/systemd/system/superset.service
    content: |
      [Unit]
      Description=Apache Superset
      After=network.target

      [Service]
      User=superset
      Group=superset
      EnvironmentFile=/etc/superset/superset.env
      ExecStart=/opt/superset/bin/gunicorn \
        --workers 4 \
        --worker-class gevent \
        --timeout 120 \
        --bind 127.0.0.1:8088 \
        "superset.app:create_app()"
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Fix dpkg state, upgrade OS, install build deps ───────────────────────
  - |
    systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
    rm -f /var/lib/dpkg/updates/*
    dpkg --configure -a
    apt-get -o DPkg::Lock::Timeout=120 -q update
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y install \
      curl nginx certbot python3-certbot-nginx \
      python3-pip python3-venv python3-dev \
      default-libmysqlclient-dev build-essential pkg-config \
      libssl-dev libffi-dev libsasl2-dev libldap2-dev \
      mysql-client

  # ── Create superset system user ───────────────────────────────────────────
  - useradd --system --create-home --home-dir /home/superset --shell /bin/false superset

  # ── Python venv + Superset ────────────────────────────────────────────────
  # Pin breaking transitive deps in the same resolver pass so pip cannot pick incompatible majors.
  - python3 -m venv /opt/superset
  - /opt/superset/bin/pip install --quiet --upgrade pip wheel
  - /opt/superset/bin/pip install --quiet \
      "apache-superset==${superset_version}" \
      "marshmallow>=3.18.0,<4.0.0" \
      "flask<3.0.0" \
      "Werkzeug<3.0.0" \
      "setuptools>=68,<70" \
      mysqlclient gevent gunicorn

  # ── Generate config files ─────────────────────────────────────────────────
  - /opt/superset/bin/python3 /root/setup-superset.py

  # ── Wait for MySQL and initialise Superset ────────────────────────────────
  - |
    DB_PASS=$(base64 -d /root/db-pass.b64)
    rm -f /root/db-pass.b64
    for i in $(seq 1 60); do
      mysql -h "${db_host}" -u "${db_user}" -p"$DB_PASS" \
        "${db_name}" -e "SELECT 1" >/dev/null 2>&1 && break || true
      echo "Waiting for MySQL ($i/60)..."; sleep 5
    done
    set -a; . /etc/superset/superset.env; set +a
    /opt/superset/bin/superset db upgrade
    ADMIN_PASS=$(base64 -d /root/admin-pass.b64)
    /opt/superset/bin/superset fab create-admin \
      --username "${admin_username}" \
      --firstname Admin \
      --lastname User \
      --email "${admin_email}" \
      --password "$ADMIN_PASS"
    /opt/superset/bin/superset init
    rm -f /root/admin-pass.b64

  # ── Fix ownership ─────────────────────────────────────────────────────────
  - mkdir -p /var/lib/superset
  - chown -R superset:superset /etc/superset /opt/superset /var/lib/superset

  # ── Start Superset ────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now superset

  # ── nginx ─────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/superset.conf /etc/nginx/sites-enabled/superset.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Optional ACME HTTPS ───────────────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      for i in $(seq 1 48); do
        curl -sf http://127.0.0.1:8088/health >/dev/null 2>&1 && break
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
        || echo "WARNING: Certbot failed. Ensure DNS A record points to this IP."
    fi

  - nginx -t && systemctl reload nginx

final_message: |
  Apache Superset bootstrap complete.
  URL:      ${base_url}
  Username: ${admin_username}
  Password: set via admin_password variable
  Logs:     /var/log/cloud-init-output.log
