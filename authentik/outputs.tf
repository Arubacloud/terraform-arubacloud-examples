output "authentik_url" {
  description = "Authentik web UI URL (HTTP)."
  value       = "http://${module.network.vm_elastic_ip_address}:9000"
}

output "authentik_url_https" {
  description = "Authentik web UI URL (HTTPS, self-signed cert)."
  value       = "https://${module.network.vm_elastic_ip_address}:9443"
}

output "vm_public_ip" {
  description = "Public IP address of the Authentik VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}
