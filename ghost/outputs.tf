output "site_url" {
  description = "URL to the Ghost site."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "ghost_admin_url" {
  description = "URL to the Ghost admin panel (first visit registers the admin account)."
  value       = var.domain != "" ? "https://${var.domain}/ghost" : "http://${module.network.vm_elastic_ip_address}/ghost"
}

output "ssh_command" {
  description = "SSH command to connect to the Ghost VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the CloudServer VM."
  value       = module.network.vm_elastic_ip_address
}

output "dbaas_host" {
  description = "Hostname / IP of the Managed MySQL DBaaS instance."
  value       = module.network.dbaas_elastic_ip_address
}

output "db_name" {
  description = "Ghost database name."
  value       = arubacloud_database.ghost.name
}

output "db_user" {
  description = "Ghost database username."
  value       = arubacloud_dbaasuser.ghost.username
}

output "db_password" {
  description = "Ghost database password."
  value       = var.db_password
  sensitive   = true
}
