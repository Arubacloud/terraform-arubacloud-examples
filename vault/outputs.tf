output "vault_url" {
  description = "Vault API and UI endpoint. Vault uses a self-signed TLS certificate — set VAULT_SKIP_VERIFY=true or trust the certificate."
  value       = "https://${module.network.vm_elastic_ip_address}:8200"
}

output "vm_public_ip" {
  description = "Public IP address of the Vault VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "init_output_cmd" {
  description = "Command to retrieve the Vault init output (unseal keys + root token). Move these to a secure location immediately."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'sudo cat /root/vault-init.json'"
}

output "env_hint" {
  description = "Environment variables to set before using the Vault CLI."
  value       = "export VAULT_ADDR=https://${module.network.vm_elastic_ip_address}:8200 VAULT_SKIP_VERIFY=true"
}
