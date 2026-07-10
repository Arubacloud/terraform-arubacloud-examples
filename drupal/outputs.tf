output "site_url" {
  description = "Drupal site URL."
  value       = local.site_url
}

output "admin_url" {
  description = "Drupal admin panel URL."
  value       = "${local.site_url}/user/login"
}

output "vm_public_ip" {
  description = "Public IP address of the Drupal VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "db_host" {
  description = "MySQL DBaaS host address."
  value       = module.network.dbaas_elastic_ip_address
}
