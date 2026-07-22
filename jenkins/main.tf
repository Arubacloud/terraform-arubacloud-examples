locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["jenkins", var.environment, "ci"]
  base_url    = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
  server_name = var.domain != "" ? var.domain : "_"
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "Jenkins CI/CD server (${var.environment})"
  tags        = local.tags
}

# ── Networking ────────────────────────────────────────────────────────────────

module "network" {
  source = "../modules/network"

  name_prefix    = local.name_prefix
  location       = var.location
  project_id     = arubacloud_project.this.id
  tags           = local.tags
  billing_period = var.billing_period

  vm_ingress_ports = {
    ssh   = { port = "22", cidr = var.ssh_cidr }
    http  = { port = "80", cidr = "0.0.0.0/0" }
    https = { port = "443", cidr = "0.0.0.0/0" }
    jnlp  = { port = "50000", cidr = var.agent_cidr }
  }
}

# ── Storage ───────────────────────────────────────────────────────────────────

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

# ── SSH key pair ──────────────────────────────────────────────────────────────

resource "arubacloud_keypair" "this" {
  name       = "${local.name_prefix}-keypair"
  location   = var.location
  project_id = arubacloud_project.this.id
  value      = var.ssh_public_key
}

# ── Cloud Server ──────────────────────────────────────────────────────────────

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
      base_url          = local.base_url
      server_name       = local.server_name
      domain            = var.domain
      acme_eab_kid      = var.acme_eab_kid
      acme_eab_hmac_key = var.acme_eab_hmac_key
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }
}
