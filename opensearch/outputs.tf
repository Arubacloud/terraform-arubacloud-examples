output "opensearch_url" {
  description = "OpenSearch REST API URL (HTTPS, accessible from admin_cidr only)."
  value       = "https://${module.network.vm_elastic_ip_address}:9200"
}

output "vm_public_ip" {
  description = "Public IP address of the OpenSearch VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "health_check" {
  description = "curl command to verify OpenSearch is running (requires admin_password)."
  value       = "curl -ku admin:<password> https://${module.network.vm_elastic_ip_address}:9200/_cluster/health?pretty"
}
