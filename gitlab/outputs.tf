output "gitlab_url" {
  description = "GitLab web UI URL."
  value       = local.external_url
}

output "vm_public_ip" {
  description = "Public IP address of the GitLab VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "git_ssh_clone" {
  description = "Example SSH git clone URL (replace <user> and <project>)."
  value       = "git clone ssh://git@${var.gitlab_hostname}:2222/<user>/<project>.git"
}
