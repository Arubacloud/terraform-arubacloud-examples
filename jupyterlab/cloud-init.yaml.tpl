#cloud-config
# JupyterLab bootstrap for Aruba Cloud.
# Python venv + JupyterLab + nginx reverse proxy + optional ACME HTTPS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: false

write_files:
  # ── Password placeholder (base64-encoded) ─────────────────────────────────
  - path: /root/jupyter-pass.b64
    permissions: "0600"
    content: "${jupyter_password_b64}"

  # ── Python setup script: hashes the password and writes the server config ─
  - path: /root/setup-jupyter.py
    permissions: "0700"
    content: |
      import base64, pathlib
      from jupyter_server.auth import passwd

      raw  = pathlib.Path('/root/jupyter-pass.b64').read_text().strip()
      pw   = base64.b64decode(raw).decode()
      hashed = passwd(pw)

      pathlib.Path('/root/jupyter-pass.b64').unlink()
      pathlib.Path('/root/setup-jupyter.py').unlink()

      cfg = (
          "c.ServerApp.ip = '127.0.0.1'\n"
          "c.ServerApp.port = 8888\n"
          "c.ServerApp.open_browser = False\n"
          "c.ServerApp.root_dir = '/opt/notebooks'\n"
          "c.ServerApp.token = ''\n"
          "c.ServerApp.allow_password_change = False\n"
          f"c.ServerApp.password = '{hashed}'\n"
      )
      pathlib.Path('/etc/jupyterlab/jupyter_server_config.py').write_text(cfg)

  # ── nginx reverse proxy ───────────────────────────────────────────────────
  - path: /etc/nginx/sites-available/jupyterlab.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              proxy_pass         http://127.0.0.1:8888;
              proxy_http_version 1.1;
              proxy_set_header   Upgrade    $${http_upgrade};
              proxy_set_header   Connection "upgrade";
              proxy_set_header   Host       $${host};
              proxy_set_header   X-Real-IP  $${remote_addr};
              proxy_set_header   X-Forwarded-For   $${proxy_add_x_forwarded_for};
              proxy_set_header   X-Forwarded-Proto $${scheme};
              proxy_read_timeout 86400;
          }
      }

  # ── systemd unit ──────────────────────────────────────────────────────────
  - path: /etc/systemd/system/jupyterlab.service
    content: |
      [Unit]
      Description=JupyterLab
      After=network.target

      [Service]
      User=jupyter
      Group=jupyter
      WorkingDirectory=/opt/notebooks
      ExecStart=/opt/jupyterlab/bin/jupyter lab \
        --config=/etc/jupyterlab/jupyter_server_config.py
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Fix dpkg state, upgrade OS, install base packages ───────────────────
  - |
    systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
    rm -f /var/lib/dpkg/updates/*
    dpkg --configure -a
    apt-get -o DPkg::Lock::Timeout=120 -q update
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 -y install \
      curl nginx certbot python3-certbot-nginx python3-pip python3-venv

  # ── Create jupyter system user ────────────────────────────────────────────
  - useradd --system --create-home --home-dir /opt/notebooks --shell /bin/bash jupyter

  # ── Python virtualenv + JupyterLab ───────────────────────────────────────
  - python3 -m venv /opt/jupyterlab
  - /opt/jupyterlab/bin/pip install --quiet --upgrade pip
  - /opt/jupyterlab/bin/pip install --quiet jupyterlab

  # ── Config directory + run setup script ──────────────────────────────────
  - mkdir -p /etc/jupyterlab
  - /opt/jupyterlab/bin/python3 /root/setup-jupyter.py

  # ── Fix ownership ─────────────────────────────────────────────────────────
  - chown -R jupyter:jupyter /opt/jupyterlab /opt/notebooks
  - chmod 750 /opt/notebooks

  # ── Start JupyterLab ─────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now jupyterlab

  # ── nginx ─────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/jupyterlab.conf /etc/nginx/sites-enabled/jupyterlab.conf
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
        curl -sf http://127.0.0.1:8888/api >/dev/null 2>&1 && break
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
  JupyterLab bootstrap complete.
  URL:      ${base_url}
  Password: set via jupyter_password variable
  Logs:     /var/log/cloud-init-output.log
