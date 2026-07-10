output "dashboard_url" {
  description = "Wazuh dashboard URL (accessible from admin_cidr only)."
  value       = "https://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the Wazuh VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "agent_manager_ip" {
  description = "IP address to configure in Wazuh agent ossec.conf as the manager address."
  value       = module.network.vm_elastic_ip_address
}
