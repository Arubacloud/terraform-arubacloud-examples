output "sonarqube_url" {
  description = "SonarQube web interface URL."
  value       = "http://${module.network.vm_elastic_ip_address}:9000"
}

output "vm_public_ip" {
  description = "Public IP address of the SonarQube VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
