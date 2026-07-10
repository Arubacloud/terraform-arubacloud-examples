#cloud-config
# Pi-hole DNS ad-blocker bootstrap for Aruba Cloud.
# Installs Pi-hole via the official installer in unattended mode.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl

write_files:
  # Pi-hole password (base64-encoded)
  - path: /root/pihole-pass.b64
    permissions: "0600"
    content: "${pihole_pass_b64}"

runcmd:
  # ── Disable systemd-resolved stub listener (conflicts with Pi-hole on port 53) ─
  - |
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/'  /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    # Re-point /etc/resolv.conf to a non-stub resolver temporarily
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  # ── Detect primary interface and IP for Pi-hole setupVars ─────────────────────
  - |
    IFACE=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    PREFIX=$(ip -o -4 addr show "$IFACE" | awk '{print $4}' | cut -d/ -f2)
    PREFIX=$${PREFIX:-24}

    mkdir -p /etc/pihole
    cat > /etc/pihole/setupVars.conf <<EOF
    PIHOLE_INTERFACE=$IFACE
    IPV4_ADDRESS=$LOCAL_IP/$PREFIX
    QUERY_LOGGING=true
    INSTALL_WEB_SERVER=true
    INSTALL_WEB_INTERFACE=true
    LIGHTTPD_ENABLED=true
    CACHE_SIZE=10000
    DNS_FQDN_REQUIRED=false
    DNS_BOGUS_PRIV=true
    DNSSEC=false
    DNSMASQ_LISTENING=all
    WEBPASSWORD=
    BLOCKING_ENABLED=true
    PIHOLE_DNS_1=${upstream_dns_1}
    PIHOLE_DNS_2=${upstream_dns_2}
    EOF

  # ── Install Pi-hole (unattended) ──────────────────────────────────────────────
  - |
    curl -sSL https://install.pi-hole.net \
      | PIHOLE_SKIP_OS_CHECK=true bash /dev/stdin --unattended

  # ── Set admin password ────────────────────────────────────────────────────────
  - |
    PIHOLE_PASS=$(base64 -d /root/pihole-pass.b64)
    pihole -a -p "$PIHOLE_PASS"
    rm -f /root/pihole-pass.b64

  # ── Enable Pi-hole services ───────────────────────────────────────────────────
  - systemctl enable pihole-FTL
  - systemctl restart pihole-FTL

final_message: |
  Pi-hole bootstrap complete.
  Admin UI: http://<IP>/admin  (accessible from admin_cidr only)
  DNS server: <IP>:53
  Configure VPN clients to use <IP> as their DNS server.
  Logs: /var/log/cloud-init-output.log
