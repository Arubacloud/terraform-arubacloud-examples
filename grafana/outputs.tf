output "grafana_url" {
  description = "Grafana web interface URL."
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

output "grafana_admin_password" {
  description = "Grafana admin password."
  value       = var.grafana_admin_password
  sensitive   = true
}
