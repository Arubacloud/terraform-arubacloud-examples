output "web_url" {
  description = "URL of the Forgejo web interface."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "ssh_clone_base" {
  description = "Base SSH clone URL. Append /<owner>/<repo>.git to clone a repository."
  value       = "ssh://git@${module.network.vm_elastic_ip_address}:2222"
}

output "vm_public_ip" {
  description = "Public IP address of the CloudServer VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "dbaas_host" {
  description = "Hostname / IP of the Managed MySQL DBaaS instance. Null when enable_mysql = false."
  value       = var.enable_mysql ? module.network.dbaas_elastic_ip_address : null
}

output "db_password" {
  description = "Forgejo database password. Only set when enable_mysql = true."
  value       = var.enable_mysql ? var.db_password : null
  sensitive   = true
}
