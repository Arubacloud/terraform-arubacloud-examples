output "jenkins_url" {
  description = "URL of the Jenkins web interface."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the Jenkins VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the Jenkins VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "initial_password_cmd" {
  description = "Command to retrieve the Jenkins initial admin password."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "jnlp_agent_port" {
  description = "JNLP port for connecting remote build agents."
  value       = "50000"
}
