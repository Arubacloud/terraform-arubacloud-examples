output "app_url"     { value = "http://${module.network.vm_elastic_ip_address}:${var.kuma_port}"; description = "Uptime Kuma web UI URL." }
output "ssh_command" { value = "ssh ubuntu@${module.network.vm_elastic_ip_address}";              description = "SSH command." }
output "public_ip"   { value = module.network.vm_elastic_ip_address;                              description = "VM public IP." }
