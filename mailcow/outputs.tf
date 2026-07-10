output "mailcow_url" {
  description = "Mailcow web UI URL (HTTPS — DNS must resolve to the VM IP before TLS is issued)."
  value       = "https://${var.mail_hostname}"
}

output "vm_public_ip" {
  description = "Public IP address of the Mailcow VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
