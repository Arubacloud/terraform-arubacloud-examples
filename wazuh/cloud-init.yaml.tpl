#cloud-config
# Wazuh 4.x all-in-one bootstrap for Aruba Cloud.
# Installs Wazuh Indexer, Manager, and Dashboard on a single node using the
# official Wazuh quick-install script. Sets the dashboard admin password.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# WARNING: Bootstrap takes 20-30 minutes and requires 16 GB RAM minimum.
# The VM will be unresponsive during OpenSearch initialisation.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg

write_files:
  # Admin password stored base64-encoded
  - path: /root/wazuh-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

runcmd:
  # ── Tune kernel for OpenSearch ────────────────────────────────────────────────
  - sysctl -w vm.max_map_count=262144
  - echo "vm.max_map_count=262144" >> /etc/sysctl.d/99-wazuh.conf

  # ── Download Wazuh quick-install script and config ────────────────────────────
  - |
    cd /root
    curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
    curl -sO https://packages.wazuh.com/4.x/config.yml

  # ── Patch config.yml with the local IP for single-node deployment ──────────────
  - |
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    sed -i "s/<indexer-node-ip>/$LOCAL_IP/g"  /root/config.yml
    sed -i "s/<wazuh-manager-ip>/$LOCAL_IP/g" /root/config.yml
    sed -i "s/<dashboard-node-ip>/$LOCAL_IP/g" /root/config.yml

  # ── Run the all-in-one installer (20-30 minutes) ──────────────────────────────
  - |
    cd /root
    bash wazuh-install.sh --all-in-one --ignore-check 2>&1 \
      | tee /var/log/wazuh-install.log

  # ── Change the dashboard admin password ────────────────────────────────────────
  - |
    ADMIN_PASS=$(base64 -d /root/wazuh-admin.b64)
    rm -f /root/wazuh-admin.b64

    # Wait for the indexer to be ready (up to 5 minutes)
    for i in $(seq 1 30); do
      curl -sSk "https://localhost:9200" -u "admin:admin" >/dev/null 2>&1 \
        && { echo "Indexer ready after $((i * 10))s"; break; }
      sleep 10
    done

    # Change admin password via the Wazuh password tool
    bash /root/wazuh-install-files/wazuh-passwords-tool.sh \
      -u admin -p "$ADMIN_PASS" -A 2>&1 \
      | tee /var/log/wazuh-password-change.log

    # Restart services to apply new credentials
    systemctl restart wazuh-indexer
    systemctl restart wazuh-manager
    systemctl restart wazuh-dashboard

final_message: |
  Wazuh bootstrap complete (took ~20-30 minutes).
  Dashboard: https://<IP>  (accessible from admin_cidr only)
  Login: admin / your admin_password
  Agent manager IP: <IP>  (use this in agent ossec.conf)
  Install logs: /var/log/wazuh-install.log
  cloud-init log: /var/log/cloud-init-output.log
