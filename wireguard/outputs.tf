output "server_public_ip" {
  description = "Public IP address of the WireGuard server."
  value       = module.network.vm_elastic_ip_address
}

output "vpn_port" {
  description = "UDP port the WireGuard server listens on."
  value       = var.vpn_port
}

output "ssh_command" {
  description = "SSH command to connect to the server."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "get_server_pubkey_command" {
  description = "Run this command to retrieve the server's WireGuard public key (needed for client configs)."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'sudo cat /etc/wireguard/server.pub'"
}

output "client_config_template" {
  description = "WireGuard client configuration template. Replace <SERVER_PUBKEY> with the output of get_server_pubkey_command and <CLIENT_PRIVATE_KEY> with your client private key."
  value       = <<-EOT
    [Interface]
    Address = 10.8.0.2/32
    PrivateKey = <CLIENT_PRIVATE_KEY>
    DNS = ${join(", ", var.dns_servers)}

    [Peer]
    PublicKey = <SERVER_PUBKEY>
    Endpoint = ${module.network.vm_elastic_ip_address}:${var.vpn_port}
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
  EOT
}
