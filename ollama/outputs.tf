output "ollama_url" {
  description = "Ollama REST API URL (accessible from api_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:11434"
}

output "vm_public_ip" {
  description = "Public IP address of the Ollama VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "health_check" {
  description = "curl command to verify Ollama is running."
  value       = "curl http://${module.network.vm_elastic_ip_address}:11434/api/tags"
}
