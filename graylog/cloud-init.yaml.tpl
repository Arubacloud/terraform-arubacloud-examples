#cloud-config
# Graylog bootstrap for Aruba Cloud.
# Deployed via Docker Compose: MongoDB + OpenSearch + Graylog (all-in-one).
# Rendered by Terraform templatefile() — do not use this file directly.
#
# Bootstrap takes 5-10 minutes. OpenSearch initialisation is the slowest step.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg
  - pwgen

write_files:
  # Credentials stored base64-encoded
  - path: /root/graylog-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  - path: /root/graylog-secret.b64
    permissions: "0600"
    content: "${graylog_secret_b64}"

  # Docker Compose stack
  - path: /opt/graylog/docker-compose.yml
    content: |
      services:
        mongodb:
          image: mongo:6
          container_name: graylog-mongodb
          restart: unless-stopped
          volumes:
            - mongodb-data:/data/db

        opensearch:
          image: opensearchproject/opensearch:2
          container_name: graylog-opensearch
          restart: unless-stopped
          environment:
            - cluster.name=graylog
            - node.name=graylog-os-1
            - discovery.type=single-node
            - OPENSEARCH_INITIAL_ADMIN_PASSWORD=$${OPENSEARCH_PASSWORD}
            - DISABLE_INSTALL_DEMO_CONFIG=false
          ulimits:
            memlock:
              soft: -1
              hard: -1
            nofile:
              soft: 65536
              hard: 65536
          volumes:
            - opensearch-data:/usr/share/opensearch/data

        graylog:
          image: graylog/graylog:${graylog_version}
          container_name: graylog
          restart: unless-stopped
          depends_on:
            - mongodb
            - opensearch
          environment:
            GRAYLOG_PASSWORD_SECRET: $${GRAYLOG_PASSWORD_SECRET}
            GRAYLOG_ROOT_PASSWORD_SHA2: $${GRAYLOG_ROOT_PASSWORD_SHA2}
            GRAYLOG_HTTP_EXTERNAL_URI: http://0.0.0.0:9000/
            GRAYLOG_ELASTICSEARCH_HOSTS: https://admin:$${OPENSEARCH_PASSWORD}@opensearch:9200
            GRAYLOG_ELASTICSEARCH_VERSION: 7
          ports:
            - "9000:9000"
            - "1514:1514"
            - "1514:1514/udp"
            - "12201:12201/udp"

      volumes:
        mongodb-data:
        opensearch-data:

runcmd:
  # ── Kernel settings for OpenSearch ───────────────────────────────────────────
  - sysctl -w vm.max_map_count=262144
  - echo "vm.max_map_count=262144" > /etc/sysctl.d/99-opensearch.conf

  # ── Install Docker CE ─────────────────────────────────────────────────────────
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
  - usermod -aG docker ubuntu

  # ── Prepare credentials ───────────────────────────────────────────────────────
  - |
    ADMIN_PASS=$(base64 -d /root/graylog-admin.b64)
    GRAYLOG_SECRET=$(base64 -d /root/graylog-secret.b64)
    rm -f /root/graylog-admin.b64 /root/graylog-secret.b64

    # SHA2 hash of the admin password (required by Graylog)
    ADMIN_PASS_SHA2=$(echo -n "$ADMIN_PASS" | sha256sum | awk '{print $1}')

    # Generate a random OpenSearch password for internal use
    OS_PASS=$(pwgen -s 16 1)

    printf \
      "GRAYLOG_PASSWORD_SECRET=%s\nGRAYLOG_ROOT_PASSWORD_SHA2=%s\nOPENSEARCH_PASSWORD=%s\n" \
      "$GRAYLOG_SECRET" "$ADMIN_PASS_SHA2" "$OS_PASS" \
      > /opt/graylog/.env
    chmod 600 /opt/graylog/.env

  # ── Start the stack ───────────────────────────────────────────────────────────
  - cd /opt/graylog && docker compose up -d

  # ── Wait for Graylog to be ready ─────────────────────────────────────────────
  - |
    echo "Waiting for Graylog (may take 5-10 minutes)..."
    for i in $(seq 1 120); do
      HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:9000/api/)
      [ "$HTTP_CODE" = "200" ] && { echo "Graylog ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  Graylog bootstrap complete.
  Web UI: http://<IP>:9000  (admin / your graylog_admin_password)
  Syslog TCP/UDP: <IP>:1514
  GELF UDP: <IP>:12201
  Logs: docker logs graylog -f
  cloud-init log: /var/log/cloud-init-output.log
