output "dns_server" {
  description = "DNS server address — configure this as the DNS server on your clients."
  value       = module.network.vm_elastic_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the BIND9 VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
