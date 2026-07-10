#cloud-config
# BIND9 DNS server bootstrap for Aruba Cloud.
# Configures BIND9 as a caching recursive resolver with forwarders.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - bind9
  - bind9utils
  - bind9-doc

write_files:
  # BIND9 options — caching forwarder with access control
  - path: /etc/bind/named.conf.options
    content: |
      acl dns_clients {
          ${dns_cidr};
          localhost;
          localnets;
      };

      options {
          directory "/var/cache/bind";

          forwarders {
              ${upstream_dns_1};
              ${upstream_dns_2};
          };
          forward only;

          listen-on    { any; };
          listen-on-v6 { any; };

          allow-query     { dns_clients; };
          allow-recursion { dns_clients; };

          dnssec-validation auto;
          recursion yes;
      };

runcmd:
  # ── Disable systemd-resolved stub listener (conflicts with BIND9 on :53) ──────
  - |
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/'  /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  # ── Validate config and start BIND9 ──────────────────────────────────────────
  - named-checkconf /etc/bind/named.conf
  - systemctl enable bind9
  - systemctl restart bind9

final_message: |
  BIND9 bootstrap complete.
  DNS server: <IP>:53
  Forwarders: ${upstream_dns_1}  ${upstream_dns_2}
  Allowed clients: ${dns_cidr}
  Configure clients to use <IP> as their DNS server.
  Logs: journalctl -u named -f
  cloud-init log: /var/log/cloud-init-output.log
