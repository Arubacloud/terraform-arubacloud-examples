output "litellm_url" {
  description = "LiteLLM proxy API URL (accessible from api_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:4000"
}

output "vm_public_ip" {
  description = "Public IP address of the LiteLLM VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "health_check" {
  description = "curl command to verify LiteLLM is running (requires master_key)."
  value       = "curl -H 'Authorization: Bearer <master_key>' http://${module.network.vm_elastic_ip_address}:4000/health"
}
