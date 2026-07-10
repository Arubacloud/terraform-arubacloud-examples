output "site_url" {
  description = "Discourse site URL."
  value       = "http://${local.hostname}"
}

output "vm_public_ip" {
  description = "Public IP address of the Discourse VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
