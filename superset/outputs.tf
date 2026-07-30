output "app_url" {
  description = "Apache Superset web interface URL."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "admin_password" {
  description = "Superset admin password."
  value       = var.admin_password
  sensitive   = true
}
