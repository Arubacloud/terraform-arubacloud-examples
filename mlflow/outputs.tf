output "app_url" {
  description = "MLflow tracking server URL."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}

output "vm_public_ip" {
  description = "Public IP address of the VM."
  value       = module.network.vm_elastic_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "mlflow_tracking_uri" {
  description = "MLFLOW_TRACKING_URI to set in your experiment code."
  value       = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
}
