output "proxy_url" {
  description = "HAProxy HTTP frontend URL."
  value       = "http://${module.network.vm_elastic_ip_address}"
}

output "stats_url" {
  description = "HAProxy stats page URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:8404/stats"
}

output "vm_public_ip" {
  description = "Public IP address of the HAProxy VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
