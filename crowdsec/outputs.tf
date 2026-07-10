output "vm_public_ip" {
  description = "Public IP address of the CrowdSec VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "cscli_status" {
  description = "Command to check CrowdSec agent status on the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'sudo cscli version && sudo cscli collections list'"
}
