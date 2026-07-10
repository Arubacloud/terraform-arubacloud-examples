#cloud-config
# CoreDNS DNS server bootstrap for Aruba Cloud.
# Installs CoreDNS from the official GitHub release binary.
# Configured as a caching DNS forwarder with query logging.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl

write_files:
  # CoreDNS configuration — caching forwarder to configurable upstream resolvers
  - path: /etc/coredns/Corefile
    content: |
      . {
          forward . ${upstream_dns_1} ${upstream_dns_2}
          cache 30
          log
          errors
          health :8080
      }

  # systemd service unit
  - path: /etc/systemd/system/coredns.service
    content: |
      [Unit]
      Description=CoreDNS DNS server
      Documentation=https://coredns.io
      After=network.target

      [Service]
      Type=simple
      User=coredns
      ExecStart=/usr/local/bin/coredns -conf /etc/coredns/Corefile
      Restart=on-failure
      RestartSec=5
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Disable systemd-resolved stub listener (conflicts with CoreDNS on :53) ───
  - |
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/'  /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  # ── Download CoreDNS binary ────────────────────────────────────────────────────
  - |
    COREDNS_VERSION="${coredns_version}"
    curl -sSfL \
      "https://github.com/coredns/coredns/releases/download/v$COREDNS_VERSION/coredns_$${COREDNS_VERSION}_linux_amd64.tgz" \
      | tar -xz -C /usr/local/bin coredns
    chmod +x /usr/local/bin/coredns

  # ── Create unprivileged service user ─────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false coredns 2>/dev/null || true

  # ── Set permissions and start CoreDNS ────────────────────────────────────────
  - mkdir -p /etc/coredns
  - chown coredns:coredns /etc/coredns/Corefile
  - systemctl daemon-reload
  - systemctl enable coredns
  - systemctl start coredns

final_message: |
  CoreDNS bootstrap complete.
  DNS server: <IP>:53
  Configure clients to use <IP> as their DNS server.
  Upstream resolvers: ${upstream_dns_1} ${upstream_dns_2}
  Logs: journalctl -u coredns -f
  cloud-init log: /var/log/cloud-init-output.log
