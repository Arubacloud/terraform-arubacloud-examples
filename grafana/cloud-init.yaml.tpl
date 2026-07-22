#cloud-config
# Grafana + Prometheus + Loki + Promtail + Node Exporter bootstrap for Aruba Cloud.
# All services run as systemd units; Prometheus and Loki are localhost-only.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg
  - nginx
  - certbot
  - python3-certbot-nginx
  - unzip

write_files:
  # ── Grafana admin password (base64-encoded) ────────────────────────────────
  - path: /root/grafana-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  # ── Prometheus config ─────────────────────────────────────────────────────
  - path: /etc/prometheus/prometheus.yml
    content: |
      global:
        scrape_interval:     15s
        evaluation_interval: 15s

      scrape_configs:
        - job_name: prometheus
          static_configs:
            - targets: ['localhost:9090']

        - job_name: node
          static_configs:
            - targets: ['localhost:9100']

        - job_name: loki
          static_configs:
            - targets: ['localhost:3100']

  # ── Loki config ───────────────────────────────────────────────────────────
  - path: /etc/loki/loki.yml
    content: |
      auth_enabled: false

      server:
        http_listen_port: 3100
        grpc_listen_port: 9096

      common:
        instance_addr: 127.0.0.1
        path_prefix: /var/lib/loki
        storage:
          filesystem:
            chunks_directory: /var/lib/loki/chunks
            rules_directory:  /var/lib/loki/rules
        replication_factor: 1
        ring:
          kvstore:
            store: inmemory

      query_range:
        results_cache:
          cache:
            embedded_cache:
              enabled:     true
              max_size_mb: 100

      schema_config:
        configs:
          - from: 2020-10-24
            store:        tsdb
            object_store: filesystem
            schema:       v13
            index:
              prefix: index_
              period: 24h

      limits_config:
        retention_period: 744h

  # ── Promtail config ───────────────────────────────────────────────────────
  - path: /etc/promtail/promtail.yml
    content: |
      server:
        http_listen_port: 9080
        grpc_listen_port: 0

      positions:
        filename: /var/lib/promtail/positions.yaml

      clients:
        - url: http://localhost:3100/loki/api/v1/push

      scrape_configs:
        - job_name: system
          static_configs:
            - targets:
                - localhost
              labels:
                job:    varlogs
                host:   __HOST__
                __path__: /var/log/*log

        - job_name: journal
          journal:
            max_age: 12h
            labels:
              job:  systemd-journal
              host: __HOST__
          relabel_configs:
            - source_labels: [__journal__systemd_unit]
              target_label:  unit

  # ── Grafana datasource provisioning ───────────────────────────────────────
  - path: /etc/grafana/provisioning/datasources/observability.yaml
    content: |
      apiVersion: 1
      datasources:
        - name:      Prometheus
          type:      prometheus
          uid:       prometheus
          url:       http://localhost:9090
          isDefault: true
          editable:  false

        - name:    Loki
          type:    loki
          uid:     loki
          url:     http://localhost:3100
          editable: false

  # ── Prometheus systemd unit ───────────────────────────────────────────────
  - path: /etc/systemd/system/prometheus.service
    content: |
      [Unit]
      Description=Prometheus
      After=network.target

      [Service]
      User=prometheus
      Group=prometheus
      ExecStart=/usr/local/bin/prometheus \
        --config.file=/etc/prometheus/prometheus.yml \
        --storage.tsdb.path=/var/lib/prometheus \
        --storage.tsdb.retention.time=30d \
        --web.listen-address=127.0.0.1:9090
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # ── Loki systemd unit ─────────────────────────────────────────────────────
  - path: /etc/systemd/system/loki.service
    content: |
      [Unit]
      Description=Loki
      After=network.target

      [Service]
      User=loki
      Group=loki
      ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki.yml
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # ── Promtail systemd unit ─────────────────────────────────────────────────
  - path: /etc/systemd/system/promtail.service
    content: |
      [Unit]
      Description=Promtail (log shipper)
      After=network.target loki.service

      [Service]
      User=promtail
      Group=promtail
      ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail.yml
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # ── Node Exporter systemd unit ────────────────────────────────────────────
  - path: /etc/systemd/system/node_exporter.service
    content: |
      [Unit]
      Description=Node Exporter
      After=network.target

      [Service]
      User=node_exporter
      Group=node_exporter
      ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100
      Restart=on-failure
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  # ── nginx reverse proxy for Grafana ──────────────────────────────────────
  - path: /etc/nginx/sites-available/grafana.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

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

runcmd:
  # ── System users ─────────────────────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false prometheus
  - useradd --system --no-create-home --shell /bin/false loki
  - useradd --system --no-create-home --shell /bin/false promtail
  - useradd --system --no-create-home --shell /bin/false node_exporter

  # ── Grafana APT repository ────────────────────────────────────────────────
  - |
    curl -fsSL https://apt.grafana.com/gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/grafana.gpg
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
      > /etc/apt/sources.list.d/grafana.list
    apt-get update -q
    apt-get install -y grafana

  # ── Grafana admin password ────────────────────────────────────────────────
  - |
    ADMIN_PASS=$(base64 -d /root/grafana-admin.b64)
    sed -i \
      "s|^;admin_password.*|admin_password = $ADMIN_PASS|" \
      /etc/grafana/grafana.ini || \
    grep -q '^\[security\]' /etc/grafana/grafana.ini && \
      sed -i "/^\[security\]/a admin_password = $ADMIN_PASS" /etc/grafana/grafana.ini || \
      printf '\n[security]\nadmin_password = %s\n' "$ADMIN_PASS" >> /etc/grafana/grafana.ini
    rm -f /root/grafana-admin.b64

  # ── Prometheus binary ─────────────────────────────────────────────────────
  - |
    VER="${prometheus_version}"
    curl -sSfL \
      "https://github.com/prometheus/prometheus/releases/download/v$VER/prometheus-$VER.linux-amd64.tar.gz" \
      | tar -xz -C /tmp
    mv /tmp/prometheus-$VER.linux-amd64/prometheus /usr/local/bin/
    mv /tmp/prometheus-$VER.linux-amd64/promtool   /usr/local/bin/
    rm -rf /tmp/prometheus-$VER.linux-amd64

  # ── Node Exporter binary ──────────────────────────────────────────────────
  - |
    VER="${node_exporter_version}"
    curl -sSfL \
      "https://github.com/prometheus/node_exporter/releases/download/v$VER/node_exporter-$VER.linux-amd64.tar.gz" \
      | tar -xz -C /tmp
    mv /tmp/node_exporter-$VER.linux-amd64/node_exporter /usr/local/bin/
    rm -rf /tmp/node_exporter-$VER.linux-amd64

  # ── Loki binary ───────────────────────────────────────────────────────────
  - |
    VER="${loki_version}"
    curl -sSfL \
      "https://github.com/grafana/loki/releases/download/v$VER/loki-linux-amd64.zip" \
      -o /tmp/loki.zip
    unzip -q /tmp/loki.zip loki-linux-amd64 -d /tmp
    mv /tmp/loki-linux-amd64 /usr/local/bin/loki
    chmod +x /usr/local/bin/loki
    rm -f /tmp/loki.zip

  # ── Promtail binary ───────────────────────────────────────────────────────
  - |
    VER="${loki_version}"
    curl -sSfL \
      "https://github.com/grafana/loki/releases/download/v$VER/promtail-linux-amd64.zip" \
      -o /tmp/promtail.zip
    unzip -q /tmp/promtail.zip promtail-linux-amd64 -d /tmp
    mv /tmp/promtail-linux-amd64 /usr/local/bin/promtail
    chmod +x /usr/local/bin/promtail
    rm -f /tmp/promtail.zip

  # ── Data directories ──────────────────────────────────────────────────────
  - mkdir -p /var/lib/prometheus /var/lib/loki/{chunks,rules} /var/lib/promtail
  - chown -R prometheus:prometheus /var/lib/prometheus /etc/prometheus
  - chown -R loki:loki             /var/lib/loki       /etc/loki
  - chown -R promtail:promtail     /var/lib/promtail   /etc/promtail

  # ── Resolve hostname in Promtail config ───────────────────────────────────
  - sed -i "s|__HOST__|$(hostname)|g" /etc/promtail/promtail.yml

  # ── Add promtail to adm group so it can read /var/log ────────────────────
  - usermod -aG adm promtail

  # ── Start all services ────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now prometheus node_exporter loki promtail grafana-server

  # ── nginx ─────────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/grafana.conf /etc/nginx/sites-enabled/grafana.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Optional HTTPS via Let's Encrypt ─────────────────────────────────────
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
        curl -sf http://127.0.0.1:3000/api/health >/dev/null && break
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
  Observability stack bootstrap complete.
  Grafana: ${base_url}  (user: admin)
  Prometheus: http://localhost:9090  (internal only)
  Loki:       http://localhost:3100  (internal only)
  Logs: /var/log/cloud-init-output.log
