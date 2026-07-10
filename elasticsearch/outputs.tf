output "elasticsearch_url" {
  description = "Elasticsearch REST API URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:9200"
}

output "vm_public_ip" {
  description = "Public IP address of the Elasticsearch VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "health_check" {
  description = "curl command to verify Elasticsearch is running (requires elastic_password)."
  value       = "curl -u elastic:<password> http://${module.network.vm_elastic_ip_address}:9200/_cluster/health?pretty"
}
