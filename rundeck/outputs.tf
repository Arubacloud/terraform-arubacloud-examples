output "rundeck_url" {
  description = "Rundeck web UI URL (accessible from admin_cidr only)."
  value       = local.rundeck_url
}

output "vm_public_ip" {
  description = "Public IP address of the Rundeck VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
