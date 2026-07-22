output "adminer_url" {
  description = "Adminer web interface URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}/adminer.php"
}

output "vm_public_ip" {
  description = "Public IP address of the Adminer VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "dbaas_host" {
  description = "Public IP address of the managed MySQL DBaaS instance."
  value       = module.network.dbaas_elastic_ip_address
}

output "db_admin_user" {
  description = "DBaaS admin username."
  value       = arubacloud_dbaasuser.admin.username
}

output "db_name" {
  description = "Default database created inside the DBaaS instance."
  value       = arubacloud_database.this.name
}

output "adminer_connection_hint" {
  description = "Values to enter in the Adminer login form."
  value       = "Server: ${module.network.dbaas_elastic_ip_address} | User: ${var.db_admin_user} | Password: (from db_admin_password) | Database: ${var.db_name}"
}
