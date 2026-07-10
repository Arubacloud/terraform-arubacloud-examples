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
