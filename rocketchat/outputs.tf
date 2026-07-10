output "rocketchat_url" {
  description = "Rocket.Chat web UI URL."
  value       = "http://${module.network.vm_elastic_ip_address}:3000"
}

output "vm_public_ip" {
  description = "Public IP address of the Rocket.Chat VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
