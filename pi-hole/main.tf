locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["pi-hole", var.environment, "dns"]
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "Pi-hole DNS ad-blocker (${var.environment})"
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

  # SSH and admin UI (TCP); DNS TCP and UDP handled below
  vm_ingress_ports = {
    ssh      = { port = "22", cidr = var.ssh_cidr }
    admin_ui = { port = "80", cidr = var.admin_cidr }
    dns_tcp  = { port = "53", cidr = var.dns_cidr }
  }
}

# DNS UDP — the shared module only creates TCP rules; UDP must be added separately
resource "arubacloud_securityrule" "dns_udp" {
  name              = "${local.name_prefix}-vm-dns-udp"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = module.network.vpc_id
  security_group_id = module.network.vm_security_group_id

  properties = {
    direction = "Ingress"
    protocol  = "UDP"
    port      = "53"
    target = {
      kind  = "Ip"
      value = var.dns_cidr
    }
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
      pihole_pass_b64 = base64encode(var.pihole_password)
      upstream_dns_1  = var.upstream_dns_1
      upstream_dns_2  = var.upstream_dns_2
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }

  depends_on = [arubacloud_securityrule.dns_udp]
}
