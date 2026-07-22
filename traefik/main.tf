locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["traefik", var.environment, "proxy"]

  dashboard_port_rules = var.enable_dashboard ? {
    dashboard = { port = "8080", cidr = var.dashboard_cidr }
  } : {}
}

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "Traefik reverse proxy (${var.environment})"
  tags        = local.tags
}

module "network" {
  source = "../modules/network"

  name_prefix    = local.name_prefix
  location       = var.location
  project_id     = arubacloud_project.this.id
  tags           = local.tags
  billing_period = var.billing_period

  vm_ingress_ports = merge(
    {
      ssh   = { port = "22", cidr = var.ssh_cidr }
      http  = { port = "80", cidr = "0.0.0.0/0" }
      https = { port = "443", cidr = "0.0.0.0/0" }
    },
    local.dashboard_port_rules
  )
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
      acme_email       = var.acme_email
      traefik_version  = var.traefik_version
      enable_dashboard = var.enable_dashboard
      acme_eab_kid      = var.acme_eab_kid
      acme_eab_hmac_key = var.acme_eab_hmac_key
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }
}
