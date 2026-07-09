output "app_url"       { value = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"; description = "Nextcloud URL." }
output "admin_user"    { value = var.nc_admin_user; description = "Nextcloud admin username." }
output "admin_password"{ value = var.nc_admin_password; sensitive = true; description = "Nextcloud admin password." }
output "public_ip"     { value = module.network.vm_elastic_ip_address; description = "VM public IP." }
output "dbaas_host"    { value = module.network.dbaas_elastic_ip_address; description = "DBaaS endpoint." }
output "ssh_command"   { value = "ssh ubuntu@${module.network.vm_elastic_ip_address}"; description = "SSH command." }
