output "keycloak_url" {
  description = "Keycloak URL."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "admin_console_url" {
  description = "Keycloak Admin Console URL."
  value       = var.domain != "" ? "https://${var.domain}/admin" : "http://${module.network.vm_elastic_ip_address}/admin"
}

output "vm_public_ip" {
  description = "Public IP address of the Keycloak VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "keycloak_admin" {
  description = "Keycloak admin username."
  value       = var.keycloak_admin
}

output "keycloak_admin_password" {
  description = "Keycloak admin password."
  value       = var.keycloak_admin_password
  sensitive   = true
}
