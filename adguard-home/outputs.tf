output "admin_url" {
  description = "AdGuard Home admin web interface URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}"
}

output "dns_server" {
  description = "DNS server address — configure this as the DNS server on your VPN clients."
  value       = module.network.vm_elastic_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the AdGuard Home VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "adguard_password" {
  description = "AdGuard Home admin web interface password."
  value       = var.adguard_password
  sensitive   = true
}
