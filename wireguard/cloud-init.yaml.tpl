#cloud-config
# WireGuard VPN server bootstrap template for Aruba Cloud.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true
packages:
  - wireguard
  - iptables
  - qrencode

write_files:
  - path: /etc/sysctl.d/99-wireguard.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1

runcmd:
  # Apply IP forwarding immediately (also persists across reboots via sysctl.d)
  - sysctl -p /etc/sysctl.d/99-wireguard.conf

  # Generate server key pair
  - wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub
  - chmod 600 /etc/wireguard/server.key /etc/wireguard/server.pub

  # Write wg0.conf using the generated server private key.
  # Detect the primary outbound interface for NAT masquerading.
  - |
    PRIMARY_IF=$(ip route | awk '/default/ {print $5; exit}')
    SERVER_PRIV=$(cat /etc/wireguard/server.key)
    cat > /etc/wireguard/wg0.conf <<EOF
    [Interface]
    Address    = ${vpn_server_address}
    ListenPort = ${vpn_port}
    PrivateKey = $SERVER_PRIV
    PostUp     = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
    PostDown   = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $PRIMARY_IF -j MASQUERADE
    EOF
    chmod 600 /etc/wireguard/wg0.conf

  # Enable and start WireGuard
  - systemctl enable wg-quick@wg0
  - systemctl start wg-quick@wg0

  # Write the public key to a readable location for easy retrieval
  - cp /etc/wireguard/server.pub /var/log/wg-server-pubkey.txt
  - echo "WireGuard public key:" $(cat /etc/wireguard/server.pub)

final_message: |
  WireGuard VPN server is ready.
  Retrieve the server public key:
    sudo cat /etc/wireguard/server.pub
  or remotely:
    ssh ubuntu@<SERVER_IP> 'sudo cat /etc/wireguard/server.pub'
