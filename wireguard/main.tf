locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["wireguard", var.environment, "vpn-server"]
}

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "WireGuard VPN server (${var.environment})"
  tags        = local.tags
}

module "network" {
  source = "../modules/network"

  name_prefix    = local.name_prefix
  location       = var.location
  project_id     = arubacloud_project.this.id
  tags           = local.tags
  billing_period = var.billing_period

  # SSH only — WireGuard uses UDP (added separately below)
  vm_ingress_ports = {
    ssh = { port = "22", cidr = var.ssh_cidr }
  }
}

# WireGuard UDP ingress — the shared network module only creates TCP rules,
# so non-TCP protocols must be added by the caller.
resource "arubacloud_securityrule" "wireguard_udp" {
  name              = "${local.name_prefix}-wg-udp"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = module.network.vpc_id
  security_group_id = module.network.vm_security_group_id

  properties = {
    direction = "Ingress"
    protocol  = "UDP"
    port      = tostring(var.vpn_port)
    target = {
      kind  = "Ip"
      value = "0.0.0.0/0"
    }
  }
}

resource "arubacloud_blockstorage" "boot" {
  name           = "${local.name_prefix}-boot"
  location       = var.location
  project_id     = arubacloud_project.this.id
  zone           = var.zone
  size_gb        = var.vm_disk_size_gb
  billing_period = var.billing_period
  type           = "Performance"
  bootable       = true
  image          = var.vm_image
  tags           = local.tags
}

resource "arubacloud_keypair" "this" {
  name       = "${local.name_prefix}-keypair"
  location   = var.location
  project_id = arubacloud_project.this.id
  value      = var.ssh_public_key
}

resource "arubacloud_cloudserver" "this" {
  name       = "${local.name_prefix}-vm"
  location   = var.location
  project_id = arubacloud_project.this.id
  zone       = var.zone
  tags       = local.tags

  network = {
    vpc_uri_ref            = module.network.vpc_uri
    elastic_ip_uri_ref     = module.network.vm_elastic_ip_uri
    subnet_uri_refs        = [module.network.subnet_uri]
    securitygroup_uri_refs = [module.network.vm_security_group_uri]
  }

  settings = {
    flavor_name      = var.vm_flavor
    key_pair_uri_ref = arubacloud_keypair.this.uri
    user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
      vpn_port           = var.vpn_port
      vpn_server_address = var.vpn_server_address
      dns_servers        = join(", ", var.dns_servers)
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }

  depends_on = [arubacloud_securityrule.wireguard_udp]
}
