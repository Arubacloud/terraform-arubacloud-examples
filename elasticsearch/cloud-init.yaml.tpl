#cloud-config
# Elasticsearch 8.x bootstrap for Aruba Cloud.
# Installed from the official Elastic apt repository.
# Security (x-pack) enabled; HTTP TLS disabled for simplicity (use a reverse
# proxy with TLS termination for production).
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg

write_files:
  # elastic superuser password stored base64-encoded
  - path: /root/elastic-pass.b64
    permissions: "0600"
    content: "${elastic_pass_b64}"

  # Elasticsearch configuration
  - path: /etc/elasticsearch/elasticsearch.yml
    content: |
      cluster.name: ${cluster_name}
      node.name: node-1
      network.host: 0.0.0.0
      http.port: 9200
      discovery.type: single-node
      xpack.security.enabled: true
      xpack.security.http.ssl.enabled: false
      xpack.security.transport.ssl.enabled: false

  # Kernel parameters for Elasticsearch (applied at boot)
  - path: /etc/sysctl.d/99-elasticsearch.conf
    content: |
      vm.max_map_count=262144

runcmd:
  # ── Apply kernel settings immediately ────────────────────────────────────────
  - sysctl -w vm.max_map_count=262144

  # ── Install Elasticsearch from official apt repository ────────────────────────
  - |
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch \
      | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
      https://artifacts.elastic.co/packages/8.x/apt stable main" \
      | tee /etc/apt/sources.list.d/elastic-8.x.list
    apt-get update -qq
    apt-get install -y elasticsearch

  # ── Start Elasticsearch ───────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable elasticsearch
  - systemctl start elasticsearch

  # ── Wait for Elasticsearch to be ready (401 = up, security active) ────────────
  - |
    echo "Waiting for Elasticsearch..."
    for i in $(seq 1 60); do
      HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:9200)
      { [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "200" ]; } \
        && { echo "Elasticsearch ready after $((i * 5))s (HTTP $HTTP_CODE)"; break; }
      sleep 5
    done

  # ── Set the elastic superuser password ───────────────────────────────────────
  - |
    ELASTIC_PASS=$(base64 -d /root/elastic-pass.b64)
    rm -f /root/elastic-pass.b64
    /usr/share/elasticsearch/bin/elasticsearch-reset-password \
      -u elastic -p "$ELASTIC_PASS" --batch 2>&1 \
      | tee /var/log/elasticsearch-password-reset.log

final_message: |
  Elasticsearch bootstrap complete.
  API: http://<IP>:9200  (accessible from admin_cidr only)
  Auth: elastic / your elastic_password
  Test: curl -u elastic:<password> http://<IP>:9200/_cluster/health?pretty
  Logs: journalctl -u elasticsearch -f
  cloud-init log: /var/log/cloud-init-output.log
