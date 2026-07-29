#cloud-config
# Rundeck job automation bootstrap for Aruba Cloud.
# Installs Rundeck from the official packagecloud apt repository.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg
  - openjdk-11-jre-headless

write_files:
  # Admin password stored base64-encoded to avoid shell special-character issues
  - path: /root/rundeck-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

runcmd:
  # ── Add Rundeck apt repository ────────────────────────────────────────────────
  # packages.rundeck.com uses an 'any' distro slug that works on all Ubuntu
  # versions; the old packagecloud.io script has no jammy packages.
  - |
    curl -fsSL https://packages.rundeck.com/pagerduty/rundeck/gpgkey \
      | gpg --dearmor -o /usr/share/keyrings/rundeck-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/rundeck-archive-keyring.gpg] https://packages.rundeck.com/pagerduty/rundeck/any/ any main" \
      > /etc/apt/sources.list.d/rundeck.list
    apt-get update
    apt-get install -y rundeck

  # ── Set admin password via realm.properties ────────────────────────────────────
  # Rundeck uses MD5-hashed passwords in Jetty realm.properties format.
  - |
    ADMIN_PASS=$(base64 -d /root/rundeck-admin.b64)
    MD5_HASH=$(echo -n "$ADMIN_PASS" | md5sum | awk '{print $1}')
    rm -f /root/rundeck-admin.b64
    echo "admin:MD5:$MD5_HASH,user,admin,architect,deploy,build" \
      > /etc/rundeck/realm.properties

  # ── Set the external URL so links and webhooks work correctly ─────────────────
  - |
    sed -i "s|^grails.serverURL=.*|grails.serverURL=${rundeck_url}|" \
      /etc/rundeck/rundeck-config.properties

  # ── Enable and start Rundeck ──────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable rundeckd
  - systemctl start rundeckd

final_message: |
  Rundeck bootstrap complete.
  URL:   ${rundeck_url}  (accessible from admin_cidr only)
  Login: admin / your admin_password
  Rundeck takes 1-2 minutes to start after cloud-init completes.
  Logs: journalctl -u rundeckd -f
  cloud-init log: /var/log/cloud-init-output.log
