output "public_ip" {
  value       = module.network.vm_elastic_ip_address
  description = "Traefik server public IP."
}

output "dashboard_url" {
  value       = "http://${module.network.vm_elastic_ip_address}:8080"
  description = "Traefik dashboard URL (only accessible when enable_dashboard = true)."
}

output "ssh_command" {
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
  description = "SSH command."
}
