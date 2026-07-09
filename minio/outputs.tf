output "s3_endpoint"      { value = "http://${module.network.vm_elastic_ip_address}:9000"; description = "MinIO S3 API endpoint." }
output "console_url"      { value = "http://${module.network.vm_elastic_ip_address}:9001"; description = "MinIO web console URL." }
output "root_user"        { value = var.minio_root_user; description = "MinIO root access key." }
output "root_password"    { value = var.minio_root_password; sensitive = true; description = "MinIO root secret key." }
output "public_ip"        { value = module.network.vm_elastic_ip_address; description = "VM public IP." }
output "ssh_command"      { value = "ssh ubuntu@${module.network.vm_elastic_ip_address}"; description = "SSH command." }
output "mc_alias_command" {
  value       = "mc alias set aruba http://${module.network.vm_elastic_ip_address}:9000 ${var.minio_root_user} <root_password>"
  description = "mc (MinIO Client) alias command. Replace <root_password> with the actual password."
}
