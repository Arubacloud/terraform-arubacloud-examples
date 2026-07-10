output "node_public_ips" {
  description = "Public IP addresses of the three k3s HA control-plane nodes."
  value       = { for k, v in arubacloud_elasticip.nodes : k => v.address }
}

output "ssh_commands" {
  description = "SSH commands to connect to each control-plane node."
  value       = { for k, v in arubacloud_elasticip.nodes : k => "ssh ubuntu@${v.address}" }
}

output "api_endpoints" {
  description = "k3s API server HTTPS endpoints (port 6443) for each node."
  value       = { for k, v in arubacloud_elasticip.nodes : k => "https://${v.address}:6443" }
}
