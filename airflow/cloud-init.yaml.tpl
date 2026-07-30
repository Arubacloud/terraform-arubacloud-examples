#cloud-config
# Apache Airflow bootstrap for Aruba Cloud.
# LocalExecutor + MySQL DBaaS metadata DB + nginx reverse proxy + optional ACME HTTPS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: false

write_files:
  # ── Secrets (base64-encoded) ──────────────────────────────────────────────
  - path: /root/db-pass.b64
    permissions: "0600"
    content: "${db_password_b64}"

  - path: /root/admin-pass.b64
    permissions: "0600"
    content: "${admin_password_b64}"

  # ── Python setup: generates /etc/airflow/airflow.env with URL-encoded DB conn
  - path: /root/setup-airflow-env.py
    permissions: "0700"
    content: |
      import base64, pathlib, urllib.parse, secrets

      db_pass     = base64.b64decode(pathlib.Path('/root/db-pass.b64').read_text().strip()).decode()
      db_pass_url = urllib.parse.quote(db_pass, safe='')
      secret_key  = secrets.token_hex(32)

      lines = [
          "AIRFLOW_HOME=/opt/airflow",
          "AIRFLOW__CORE__EXECUTOR=LocalExecutor",
          "AIRFLOW__CORE__LOAD_EXAMPLES=False",
          f"AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=mysql+mysqldb://airflow:{db_pass_url}@${db_host}:3306/${db_name}",
          "AIRFLOW__WEBSERVER__WEB_SERVER_HOST=127.0.0.1",
          "AIRFLOW__WEBSERVER__WEB_SERVER_PORT=8080",
          f"AIRFLOW__WEBSERVER__BASE_URL=${base_url}",
          f"AIRFLOW__WEBSERVER__SECRET_KEY={secret_key}",
          "AIRFLOW__LOGGING__BASE_LOG_FOLDER=/opt/airflow/logs",
      ]
      pathlib.Path('/etc/airflow').mkdir(parents=True, exist_ok=True)
      pathlib.Path('/etc/airflow/airflow.env').write_text('\n'.join(lines) + '\n')
      pathlib.Path('/root/db-pass.b64').unlink()
      pathlib.Path('/root/setup-airflow-env.py').unlink()

  # ── nginx reverse proxy ───────────────────────────────────────────────────
  - path: /etc/nginx/sites-available/airflow.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              proxy_pass         http://127.0.0.1:8080;
              proxy_http_version 1.1;
              proxy_set_header   Host              $${host};
              proxy_set_header   X-Real-IP         $${remote_addr};
              proxy_set_header   X-Forwarded-For   $${proxy_add_x_forwarded_for};
              proxy_set_header   X-Forwarded-Proto $${scheme};
              proxy_read_timeout 300;
          }
      }

  # ── systemd: airflow-webserver ────────────────────────────────────────────
  - path: /etc/systemd/system/airflow-webserver.service
    content: |
      [Unit]
      Description=Apache Airflow Webserver
      After=network.target airflow-scheduler.service

      [Service]
      User=airflow
      Group=airflow
      EnvironmentFile=/etc/airflow/airflow.env
      ExecStart=/opt/airflow-env/bin/airflow webserver
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target

  # ── systemd: airflow-scheduler ────────────────────────────────────────────
  - path: /etc/systemd/system/airflow-scheduler.service
    content: |
      [Unit]
      Description=Apache Airflow Scheduler
      After=network.target

      [Service]
      User=airflow
      Group=airflow
      EnvironmentFile=/etc/airflow/airflow.env
      ExecStart=/opt/airflow-env/bin/airflow scheduler
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target

  # ── systemd: airflow-triggerer ────────────────────────────────────────────
  - path: /etc/systemd/system/airflow-triggerer.service
    content: |
      [Unit]
      Description=Apache Airflow Triggerer
      After=network.target airflow-scheduler.service

      [Service]
      User=airflow
      Group=airflow
      EnvironmentFile=/etc/airflow/airflow.env
      ExecStart=/opt/airflow-env/bin/airflow triggerer
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
      mysql-client

  # ── Create airflow system user ────────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false airflow

  # ── Python venv + Airflow with MySQL provider ─────────────────────────────
  - python3 -m venv /opt/airflow-env
  - /opt/airflow-env/bin/pip install --quiet --upgrade pip
  - |
    VER="${airflow_version}"
    PY_VER=$(/opt/airflow-env/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-$VER/constraints-$PY_VER.txt"
    /opt/airflow-env/bin/pip install --quiet \
      "apache-airflow[mysql]==$VER" \
      --constraint "$CONSTRAINT_URL"

  # ── Create Airflow directories ────────────────────────────────────────────
  - mkdir -p /opt/airflow/{dags,logs,plugins}

  # ── Generate env file with URL-encoded DB connection ──────────────────────
  - /opt/airflow-env/bin/python3 /root/setup-airflow-env.py

  # ── Wait for MySQL and initialise the metadata DB ─────────────────────────
  - |
    set -a; . /etc/airflow/airflow.env; set +a
    for i in $(seq 1 60); do
      mysql -h "${db_host}" -u "${db_user}" -p"$(base64 -d /root/admin-pass.b64 2>/dev/null || true)" \
        "${db_name}" -e "SELECT 1" >/dev/null 2>&1 && break || true
      /opt/airflow-env/bin/python3 -c \
        "import MySQLdb; MySQLdb.connect(host='${db_host}', user='${db_user}', db='${db_name}')" \
        >/dev/null 2>&1 && break || true
      echo "Waiting for MySQL ($i/60)..."; sleep 5
    done
    /opt/airflow-env/bin/airflow db migrate

  # ── Create admin user ─────────────────────────────────────────────────────
  - |
    set -a; . /etc/airflow/airflow.env; set +a
    ADMIN_PASS=$(base64 -d /root/admin-pass.b64)
    /opt/airflow-env/bin/airflow users create \
      --username "${admin_user}" \
      --firstname Admin \
      --lastname User \
      --role Admin \
      --email "${admin_email}" \
      --password "$ADMIN_PASS"
    rm -f /root/admin-pass.b64

  # ── Fix ownership ─────────────────────────────────────────────────────────
  - chown -R airflow:airflow /opt/airflow /etc/airflow

  # ── Start Airflow services ────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now airflow-scheduler airflow-triggerer airflow-webserver

  # ── nginx ─────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/airflow.conf /etc/nginx/sites-enabled/airflow.conf
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
      for i in $(seq 1 36); do
        curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1 && break
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
  Apache Airflow bootstrap complete.
  URL:      ${base_url}
  Username: ${admin_user}
  Password: set via airflow_admin_password variable
  Logs:     /var/log/cloud-init-output.log
            /opt/airflow/logs/
