#cloud-config
# AdGuard Home DNS ad-blocker bootstrap for Aruba Cloud.
# Installs AdGuard Home from the official GitHub release binary.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - python3-bcrypt

write_files:
  # Admin password stored base64-encoded to avoid shell special-character issues
  - path: /root/adguard-pass.b64
    permissions: "0600"
    content: "${adguard_pass_b64}"

  # AdGuard Home config with upstream DNS pre-configured; password injected at runtime
  - path: /opt/AdGuardHome/AdGuardHome.yaml
    permissions: "0600"
    content: |
      http:
        address: 0.0.0.0:80
      users:
        - name: admin
          password: "PLACEHOLDER_PASSWORD_HASH"
      dns:
        bind_hosts:
          - 0.0.0.0
        port: 53
        upstream_dns:
          - ${upstream_dns_1}
          - ${upstream_dns_2}
        bootstrap_dns:
          - 9.9.9.10
          - 149.112.112.10
        upstream_mode: parallel
        cache_size: 4194304
        enable_dnssec: false
      filters:
        - enabled: true
          url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
          name: AdGuard DNS filter
          id: 1
        - enabled: true
          url: https://adaway.org/hosts.txt
          name: AdAway Default Blocklist
          id: 2
      querylog:
        enabled: true
        interval: 24h
      statistics:
        enabled: true
        interval: 24h

runcmd:
  # ── Disable systemd-resolved stub listener (conflicts with AdGuard Home on :53) ─
  - |
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/'  /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  # ── Download AdGuard Home binary ──────────────────────────────────────────────
  - |
    AGH_VERSION="${adguardhome_version}"
    curl -sSfL \
      "https://github.com/AdguardTeam/AdGuardHome/releases/download/v$AGH_VERSION/AdGuardHome_linux_amd64.tar.gz" \
      | tar -xz -C /tmp
    cp /tmp/AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome
    chmod +x /opt/AdGuardHome/AdGuardHome
    rm -rf /tmp/AdGuardHome

  # ── Generate bcrypt hash and inject into config ───────────────────────────────
  - |
    python3 - << 'PYEOF'
import bcrypt, base64

with open('/root/adguard-pass.b64') as f:
    pw = base64.b64decode(f.read().strip())

hashed = bcrypt.hashpw(pw, bcrypt.gensalt(10)).decode()

with open('/opt/AdGuardHome/AdGuardHome.yaml') as f:
    config = f.read()

config = config.replace('PLACEHOLDER_PASSWORD_HASH', hashed)

with open('/opt/AdGuardHome/AdGuardHome.yaml', 'w') as f:
    f.write(config)
PYEOF
    rm -f /root/adguard-pass.b64

  # ── Install AdGuard Home as a systemd service and start it ────────────────────
  - /opt/AdGuardHome/AdGuardHome --no-check-update -s install
  - systemctl enable AdGuardHome
  - systemctl start AdGuardHome

final_message: |
  AdGuard Home bootstrap complete.
  Admin UI: http://<IP>  (accessible from admin_cidr only)
  DNS server: <IP>:53
  Configure VPN clients to use <IP> as their DNS server.
  Logs: /var/log/cloud-init-output.log
  Service logs: journalctl -u AdGuardHome -f
