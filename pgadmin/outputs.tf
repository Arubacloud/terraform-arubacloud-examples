output "pgadmin_url" {
  description = "pgAdmin web interface URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}/pgadmin4"
}

output "pgadmin_email" {
  description = "pgAdmin login email address."
  value       = var.pgadmin_email
}

output "vm_public_ip" {
  description = "Public IP address of the pgAdmin VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
