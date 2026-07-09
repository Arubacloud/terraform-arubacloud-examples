output "vpc_id" {
  description = "ID of the VPC."
  value       = arubacloud_vpc.this.id
}

output "vpc_uri" {
  description = "URI of the VPC (used as vpc_uri_ref in other resources)."
  value       = arubacloud_vpc.this.uri
}

output "subnet_id" {
  description = "ID of the subnet."
  value       = arubacloud_subnet.this.id
}

output "subnet_uri" {
  description = "URI of the subnet (used as subnet_uri_ref in other resources)."
  value       = arubacloud_subnet.this.uri
}

# ── VM ────────────────────────────────────────────────────────────────────────

output "vm_security_group_id" {
  description = "ID of the VM security group."
  value       = arubacloud_securitygroup.vm.id
}

output "vm_security_group_uri" {
  description = "URI of the VM security group (used as securitygroup_uri_refs)."
  value       = arubacloud_securitygroup.vm.uri
}

output "vm_elastic_ip_address" {
  description = "Public IP address of the VM."
  value       = arubacloud_elasticip.vm.address
}

output "vm_elastic_ip_uri" {
  description = "URI of the VM Elastic IP (used as elastic_ip_uri_ref)."
  value       = arubacloud_elasticip.vm.uri
}

# ── DBaaS (null when create_dbaas_network = false) ────────────────────────────

output "dbaas_security_group_id" {
  description = "ID of the DBaaS security group. Null when create_dbaas_network is false."
  value       = var.create_dbaas_network ? arubacloud_securitygroup.dbaas[0].id : null
}

output "dbaas_security_group_uri" {
  description = "URI of the DBaaS security group. Null when create_dbaas_network is false."
  value       = var.create_dbaas_network ? arubacloud_securitygroup.dbaas[0].uri : null
}

output "dbaas_elastic_ip_address" {
  description = "Public IP address of the DBaaS Elastic IP. Null when create_dbaas_network is false."
  value       = var.create_dbaas_network ? arubacloud_elasticip.dbaas[0].address : null
}

output "dbaas_elastic_ip_uri" {
  description = "URI of the DBaaS Elastic IP. Null when create_dbaas_network is false."
  value       = var.create_dbaas_network ? arubacloud_elasticip.dbaas[0].uri : null
}
