---
title: Network Module
---

# modules/network

Shared Terraform module used by all ArubaCloud examples. Creates the foundational networking layer: VPC, subnet, VM security group with configurable ingress rules, VM Elastic IP, and (optionally) a DBaaS security group and Elastic IP.

## Why a shared module?

Every example needs the same 6–10 networking resources. Without a module, that code would be duplicated in every example directory. The module keeps examples focused on their application logic.

## Design decisions

- **App-specific security rules are NOT in this module.** For example, the WordPress example creates the MySQL 3306 rule in its own `main.tf` so it can restrict the source CIDR to `${module.network.vm_elastic_ip_address}/32`. The module only creates generic egress-all rules and the configurable VM ingress rules.
- **DBaaS networking is optional.** Set `create_dbaas_network = true` in examples that use a managed database. The DBaaS security group is created without any ingress rules — the caller adds them.
- **One subnet per VPC.** All examples use a single Basic subnet. Multi-subnet topologies are out of scope for this collection.

## Usage

```hcl
module "network" {
  source = "../modules/network"

  name_prefix  = "wp-prod"
  location     = var.location
  project_id   = arubacloud_project.this.id
  tags         = ["wordpress", "prod"]
  billing_period = "Hour"

  vm_ingress_ports = {
    ssh   = { port = "22",  cidr = var.ssh_cidr }
    http  = { port = "80",  cidr = "0.0.0.0/0" }
    https = { port = "443", cidr = "0.0.0.0/0" }
  }

  create_dbaas_network = true
}

# DBaaS-specific MySQL ingress rule (created outside the module so the
# source CIDR can reference module.network.vm_elastic_ip_address)
resource "arubacloud_securityrule" "dbaas_mysql" {
  name              = "wp-prod-db-mysql"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = module.network.vpc_id
  security_group_id = module.network.dbaas_security_group_id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "3306"
    target = {
      kind  = "Ip"
      value = "${module.network.vm_elastic_ip_address}/32"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| arubacloud/arubacloud | ~> 0.5 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Short prefix for all resource names. 2–15 chars. | `string` | — | yes |
| `location` | ArubaCloud region (e.g. `ITBG-Bergamo`) | `string` | `"ITBG-Bergamo"` | no |
| `project_id` | ArubaCloud project ID | `string` | — | yes |
| `tags` | Tags to attach to all resources | `list(string)` | `[]` | no |
| `billing_period` | Elastic IP billing period (`Hour` or `Month`) | `string` | `"Hour"` | no |
| `vm_ingress_ports` | Map of TCP ingress rules for the VM security group | `map(object({port=string, cidr=string}))` | `{ssh, http, https}` | no |
| `create_dbaas_network` | Create DBaaS security group and Elastic IP | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_uri` | VPC URI (for `vpc_uri_ref`) |
| `subnet_id` | Subnet ID |
| `subnet_uri` | Subnet URI (for `subnet_uri_refs`) |
| `vm_security_group_id` | VM security group ID |
| `vm_security_group_uri` | VM security group URI (for `securitygroup_uri_refs`) |
| `vm_elastic_ip_address` | Public IP address of the VM |
| `vm_elastic_ip_uri` | VM Elastic IP URI (for `elastic_ip_uri_ref`) |
| `dbaas_security_group_id` | DBaaS security group ID (null if `create_dbaas_network=false`) |
| `dbaas_security_group_uri` | DBaaS security group URI (null if `create_dbaas_network=false`) |
| `dbaas_elastic_ip_address` | DBaaS public IP address (null if `create_dbaas_network=false`) |
| `dbaas_elastic_ip_uri` | DBaaS Elastic IP URI (null if `create_dbaas_network=false`) |

