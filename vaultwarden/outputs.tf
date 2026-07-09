output "app_url" {
  description = "Vaultwarden web UI URL."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "admin_url" {
  description = "Vaultwarden admin panel URL (only accessible when admin_token is set)."
  value       = var.domain != "" ? "https://${var.domain}/admin" : "http://${module.network.vm_elastic_ip_address}/admin"
}

output "public_ip"   { value = module.network.vm_elastic_ip_address; description = "VM public IP." }
output "ssh_command" { value = "ssh ubuntu@${module.network.vm_elastic_ip_address}"; description = "SSH command." }
