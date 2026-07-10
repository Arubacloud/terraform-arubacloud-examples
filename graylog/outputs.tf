output "graylog_url" {
  description = "Graylog web UI URL (accessible from admin_cidr only)."
  value       = "http://${module.network.vm_elastic_ip_address}:9000"
}

output "vm_public_ip" {
  description = "Public IP address of the Graylog VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "syslog_endpoint" {
  description = "Syslog TCP/UDP endpoint for log shipping."
  value       = "${module.network.vm_elastic_ip_address}:1514"
}

output "gelf_endpoint" {
  description = "GELF UDP endpoint for structured log shipping."
  value       = "${module.network.vm_elastic_ip_address}:12201"
}
