output "home_assistant_url" {
  description = "Home Assistant web UI URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:8123"
}

output "vm_public_ip" {
  description = "Public IP address of the Home Assistant VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
