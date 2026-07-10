output "site_url" {
  description = "Mattermost URL."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the Mattermost VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "dbaas_host" {
  description = "Managed MySQL DBaaS endpoint."
  value       = module.network.dbaas_elastic_ip_address
}

output "db_name" {
  description = "Mattermost database name."
  value       = arubacloud_database.mattermost.name
}

output "db_user" {
  description = "Mattermost database username."
  value       = arubacloud_dbaasuser.mattermost.username
}

output "db_password" {
  description = "Mattermost database password."
  value       = var.db_password
  sensitive   = true
}
