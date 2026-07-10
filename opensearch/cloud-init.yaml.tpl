#cloud-config
# OpenSearch 2.x bootstrap for Aruba Cloud.
# Deployed via Docker Compose using the official opensearchproject/opensearch image.
# TLS is enabled by default on the REST API (HTTPS port 9200).
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  # admin password stored base64-encoded
  - path: /root/opensearch-pass.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  # Docker Compose stack for OpenSearch
  - path: /opt/opensearch/docker-compose.yml
    content: |
      services:
        opensearch:
          image: opensearchproject/opensearch:${opensearch_version}
          container_name: opensearch
          restart: unless-stopped
          environment:
            - cluster.name=${cluster_name}
            - node.name=node-1
            - discovery.type=single-node
            - OPENSEARCH_INITIAL_ADMIN_PASSWORD=$${OPENSEARCH_INITIAL_ADMIN_PASSWORD}
            - DISABLE_INSTALL_DEMO_CONFIG=false
            - DISABLE_SECURITY_PLUGIN=false
          ulimits:
            memlock:
              soft: -1
              hard: -1
            nofile:
              soft: 65536
              hard: 65536
          volumes:
            - opensearch-data:/usr/share/opensearch/data
          ports:
            - "9200:9200"
            - "9300:9300"

      volumes:
        opensearch-data:

runcmd:
  # ── Kernel settings ───────────────────────────────────────────────────────────
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

  # ── Start OpenSearch ──────────────────────────────────────────────────────────
  - |
    ADMIN_PASS=$(base64 -d /root/opensearch-pass.b64)
    echo "OPENSEARCH_INITIAL_ADMIN_PASSWORD=$ADMIN_PASS" > /opt/opensearch/.env
    chmod 600 /opt/opensearch/.env
    rm -f /root/opensearch-pass.b64
    cd /opt/opensearch && docker compose up -d
    echo "Waiting for OpenSearch to initialise (may take 3-5 minutes)..."
    for i in $(seq 1 72); do
      HTTP_CODE=$(curl -sk -o /dev/null -w "%%{http_code}" https://localhost:9200 -u "admin:$ADMIN_PASS")
      [ "$HTTP_CODE" = "200" ] && { echo "OpenSearch ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  OpenSearch bootstrap complete.
  API: https://<IP>:9200  (HTTPS, accessible from admin_cidr only)
  Auth: admin / your admin_password
  Test: curl -ku admin:<password> https://<IP>:9200/_cluster/health?pretty
  Logs: docker logs opensearch -f
  cloud-init log: /var/log/cloud-init-output.log
