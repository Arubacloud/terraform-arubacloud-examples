output "public_ip" {
  description = "Public IP address of the Docker host."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the Docker host."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "docker_context_command" {
  description = "Command to create a Docker context pointing at this host (SSH-based)."
  value       = "docker context create aruba-docker --docker 'host=ssh://ubuntu@${module.network.vm_elastic_ip_address}'"
}
