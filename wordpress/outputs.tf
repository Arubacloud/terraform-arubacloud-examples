output "site_url" {
  description = "URL to the WordPress site."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "wp_admin_url" {
  description = "URL to the WordPress admin dashboard."
  value       = var.domain != "" ? "https://${var.domain}/wp-admin" : "http://${module.network.vm_elastic_ip_address}/wp-admin"
}

output "wp_admin_user" {
  description = "WordPress admin username."
  value       = var.wp_admin_user
}

output "wp_admin_password" {
  description = "WordPress admin password."
  value       = var.wp_admin_password
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the WordPress VM."
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
  description = "WordPress database name."
  value       = arubacloud_database.wordpress.name
}

output "db_user" {
  description = "WordPress database username."
  value       = arubacloud_dbaasuser.wordpress.username
}

output "db_password" {
  description = "WordPress database password."
  value       = var.db_password
  sensitive   = true
}
