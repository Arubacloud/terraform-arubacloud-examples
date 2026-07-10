output "http_url" {
  description = "HTTP URL of the NGINX web server."
  value       = "http://${module.network.vm_elastic_ip_address}"
}

output "https_url" {
  description = "HTTPS URL of the NGINX web server (only valid when domain is set and Let's Encrypt certificate is issued)."
  value       = var.domain != "" ? "https://${var.domain}" : "Not configured — set the domain variable to enable HTTPS."
}

output "vm_public_ip" {
  description = "Public IP address of the NGINX VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
