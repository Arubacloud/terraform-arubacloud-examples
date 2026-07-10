output "nexus_url" {
  description = "Nexus Repository web UI URL."
  value       = "http://${module.network.vm_elastic_ip_address}:8081"
}

output "nexus_docker_registry_url" {
  description = "Docker registry URL (only active when enable_docker_registry = true)."
  value       = var.enable_docker_registry ? "${module.network.vm_elastic_ip_address}:8082" : "Docker registry not enabled"
}

output "vm_public_ip" {
  description = "Public IP address of the Nexus VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "admin_password_command" {
  description = "Command to retrieve the auto-generated Nexus admin password (run on the VM after bootstrap)."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'docker exec nexus cat /nexus-data/admin.password'"
}
