output "drone_url" {
  description = "Drone CI web UI URL. Also use this as the OAuth2 redirect base URL in Gitea."
  value       = "http://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the Drone CI VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "gitea_oauth_redirect_url" {
  description = "OAuth2 redirect URL to enter in Gitea when creating the OAuth application."
  value       = "http://${module.network.vm_elastic_ip_address}/login"
}
