#cloud-config
# MLflow tracking server bootstrap for Aruba Cloud.
# pip install + systemd + MySQL DBaaS backend + nginx (HTTP Basic Auth) + optional ACME HTTPS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: false

write_files:
  # ── Secrets (base64-encoded) ──────────────────────────────────────────────
  - path: /root/db-pass.b64
    permissions: "0600"
    content: "${db_password_b64}"

  - path: /root/ui-pass.b64
    permissions: "0600"
    content: "${mlflow_admin_password_b64}"

  # ── Python setup: writes /etc/mlflow/mlflow.env ───────────────────────────
  - path: /root/setup-mlflow-env.py
    permissions: "0700"
    content: |
      import base64, pathlib, urllib.parse

      db_pass     = base64.b64decode(pathlib.Path('/root/db-pass.b64').read_text().strip()).decode()
      db_pass_url = urllib.parse.quote(db_pass, safe='')

      pathlib.Path('/etc/mlflow').mkdir(parents=True, exist_ok=True)

      lines = [
          f"MLFLOW_BACKEND_STORE_URI=mysql+pymysql://mlflow:{db_pass_url}@${db_host}:3306/${db_name}",
          "MLFLOW_DEFAULT_ARTIFACT_ROOT=/opt/mlflow/artifacts",
          "MLFLOW_HOST=127.0.0.1",
          "MLFLOW_PORT=5000",
      ]
      pathlib.Path('/etc/mlflow/mlflow.env').write_text('\n'.join(lines) + '\n')
      pathlib.Path('/root/setup-mlflow-env.py').unlink()

  # ── nginx reverse proxy with HTTP Basic Auth ──────────────────────────────
  - path: /etc/nginx/sites-available/mlflow.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              auth_basic           "MLflow";
              auth_basic_user_file /etc/nginx/mlflow.htpasswd;

              proxy_pass         http://127.0.0.1:5000;
              proxy_http_version 1.1;
              proxy_set_header   Host              $${host};
              proxy_set_header   X-Real-IP         $${remote_addr};
              proxy_set_header   X-Forwarded-For   $${proxy_add_x_forwarded_for};
              proxy_set_header   X-Forwarded-Proto $${scheme};
              proxy_read_timeout 300;
              client_max_body_size 500M;
          }
      }

  # ── systemd: mlflow ───────────────────────────────────────────────────────
  - path: /etc/systemd/system/mlflow.service
    content: |
      [Unit]
      Description=MLflow Tracking Server
      After=network.target

      [Service]
      User=mlflow
      Group=mlflow
      EnvironmentFile=/etc/mlflow/mlflow.env
      ExecStart=/opt/mlflow-env/bin/mlflow server \
        --backend-store-uri $${MLFLOW_BACKEND_STORE_URI} \
        --default-artifact-root $${MLFLOW_DEFAULT_ARTIFACT_ROOT} \
        --host $${MLFLOW_HOST} \
        --port $${MLFLOW_PORT}
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Fix dpkg state, upgrade OS, install packages ─────────────────────────
  - |
    systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
    rm -f /var/lib/dpkg/updates/*
    dpkg --configure -a
    apt-get -o DPkg::Lock::Timeout=120 -q update
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y install \
      curl nginx certbot python3-certbot-nginx \
      python3-pip python3-venv apache2-utils mysql-client

  # ── Create mlflow system user ─────────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false mlflow

  # ── Python venv + MLflow ──────────────────────────────────────────────────
  - python3 -m venv /opt/mlflow-env
  - /opt/mlflow-env/bin/pip install --quiet --upgrade pip
  - /opt/mlflow-env/bin/pip install --quiet "mlflow==${mlflow_version}" pymysql

  # ── Artifact storage directory ────────────────────────────────────────────
  - mkdir -p /opt/mlflow/artifacts

  # ── Generate env file ─────────────────────────────────────────────────────
  - /opt/mlflow-env/bin/python3 /root/setup-mlflow-env.py

  # ── Create nginx Basic Auth credentials ───────────────────────────────────
  - |
    UI_PASS=$(base64 -d /root/ui-pass.b64)
    htpasswd -c -b /etc/nginx/mlflow.htpasswd "${mlflow_admin_user}" "$UI_PASS"
    rm -f /root/ui-pass.b64
    chown root:www-data /etc/nginx/mlflow.htpasswd
    chmod 640 /etc/nginx/mlflow.htpasswd

  # ── Wait for MySQL, then run DB migrations ───────────────────────────────
  - |
    DB_PASS=$(base64 -d /root/db-pass.b64)
    rm -f /root/db-pass.b64
    for i in $(seq 1 60); do
      mysql -h "${db_host}" -u "${db_user}" -p"$DB_PASS" \
        "${db_name}" -e "SELECT 1" >/dev/null 2>&1 && break || true
      echo "Waiting for MySQL ($i/60)..."; sleep 5
    done
    set -a; . /etc/mlflow/mlflow.env; set +a
    /opt/mlflow-env/bin/mlflow db upgrade "$MLFLOW_BACKEND_STORE_URI"

  # ── Fix ownership ─────────────────────────────────────────────────────────
  - chown -R mlflow:mlflow /opt/mlflow /opt/mlflow-env /etc/mlflow

  # ── Start MLflow ──────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now mlflow

  # ── nginx ─────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/mlflow.conf /etc/nginx/sites-enabled/mlflow.conf
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
      for i in $(seq 1 24); do
        curl -sf http://127.0.0.1:5000/health >/dev/null 2>&1 && break
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
  MLflow bootstrap complete.
  URL:      ${base_url}
  Username: ${mlflow_admin_user}
  Password: set via mlflow_admin_password variable
  Set in your experiment code:
    import mlflow
    mlflow.set_tracking_uri("${base_url}")
  Logs: /var/log/cloud-init-output.log
