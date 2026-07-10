output "wikijs_url" {
  description = "Wiki.js web UI URL."
  value       = "http://${module.network.vm_elastic_ip_address}:3000"
}

output "vm_public_ip" {
  description = "Public IP address of the Wiki.js VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "db_host" {
  description = "Public IP address of the managed MySQL DBaaS instance."
  value       = module.network.dbaas_elastic_ip_address
}
