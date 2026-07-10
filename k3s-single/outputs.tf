output "vm_public_ip" {
  description = "Public IP address of the k3s node."
  value       = module.network.vm_elastic_ip_address
}

output "api_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = "https://${module.network.vm_elastic_ip_address}:6443"
}

output "ssh_command" {
  description = "SSH command to connect to the node."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address}"
}

output "kubeconfig_cmd" {
  description = "Command to fetch the kubeconfig and configure kubectl on your local machine."
  value       = "ssh ubuntu@${module.network.vm_elastic_ip_address} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's|https://127.0.0.1:6443|https://${module.network.vm_elastic_ip_address}:6443|' > ~/.kube/k3s-arubacloud.yaml && export KUBECONFIG=~/.kube/k3s-arubacloud.yaml"
}
