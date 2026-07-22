locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["wordpress", var.environment]
  site_url    = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"

  # The ArubaCloud DBaaS API stores the base64 of the password as the MySQL password.
  db_password_php = base64encode(var.db_password)
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "WordPress ${var.environment} deployment"
  tags        = local.tags
}

# ── Networking ────────────────────────────────────────────────────────────────

module "network" {
  source = "../modules/network"

  name_prefix          = local.name_prefix
  location             = var.location
  project_id           = arubacloud_project.this.id
  tags                 = local.tags
  billing_period       = var.billing_period
  create_dbaas_network = true

  vm_ingress_ports = {
    ssh   = { port = "22", cidr = var.ssh_cidr }
    http  = { port = "80", cidr = "0.0.0.0/0" }
    https = { port = "443", cidr = "0.0.0.0/0" }
  }
}

# Restrict MySQL access to the VM's IP only
resource "arubacloud_securityrule" "dbaas_mysql" {
  name              = "${local.name_prefix}-db-mysql"
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

# ── Managed MySQL ─────────────────────────────────────────────────────────────

resource "arubacloud_dbaas" "this" {
  name       = "${local.name_prefix}-dbaas"
  location   = var.location
  zone       = var.zone
  project_id = arubacloud_project.this.id
  engine_id  = "mysql-8.0"
  flavor     = var.dbaas_flavor
  tags       = local.tags

  storage = {
    size_gb = var.db_storage_gb
    autoscaling = {
      enabled         = true
      available_space = 2
      step_size       = 5
    }
  }

  network = {
    vpc_uri_ref            = module.network.vpc_uri
    subnet_uri_ref         = module.network.subnet_uri
    security_group_uri_ref = module.network.dbaas_security_group_uri
    elastic_ip_uri_ref     = module.network.dbaas_elastic_ip_uri
  }

  billing_period = var.billing_period
}

resource "arubacloud_database" "wordpress" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  name       = "wordpress"
}

resource "arubacloud_dbaasuser" "wordpress" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  username   = "wordpress"
  password   = var.db_password
}

resource "arubacloud_databasegrant" "wordpress" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  database   = arubacloud_database.wordpress.id
  user_id    = arubacloud_dbaasuser.wordpress.id
  role       = "liteadmin"
}

# ── WordPress security keys ───────────────────────────────────────────────────
# Generated once and stored in state; never change unless explicitly rotated.

resource "random_password" "wp_keys" {
  for_each = toset([
    "auth_key", "secure_auth_key", "logged_in_key", "nonce_key",
    "auth_salt", "secure_auth_salt", "logged_in_salt", "nonce_salt",
  ])

  length  = 64
  special = true
  # Exclude ' and \ — safe for PHP single-quoted string literals
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
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
      db_host           = module.network.dbaas_elastic_ip_address
      db_name           = arubacloud_database.wordpress.name
      db_user           = arubacloud_dbaasuser.wordpress.username
      db_password_php   = local.db_password_php
      wp_admin_user     = var.wp_admin_user
      wp_admin_pass_b64 = base64encode(var.wp_admin_password)
      wp_admin_email    = var.wp_admin_email
      wp_title          = var.wp_title
      wp_url            = local.site_url
      domain            = var.domain
      auth_key          = random_password.wp_keys["auth_key"].result
      secure_auth_key   = random_password.wp_keys["secure_auth_key"].result
      logged_in_key     = random_password.wp_keys["logged_in_key"].result
      nonce_key         = random_password.wp_keys["nonce_key"].result
      auth_salt         = random_password.wp_keys["auth_salt"].result
      secure_auth_salt  = random_password.wp_keys["secure_auth_salt"].result
      logged_in_salt    = random_password.wp_keys["logged_in_salt"].result
      nonce_salt        = random_password.wp_keys["nonce_salt"].result
      acme_eab_kid      = var.acme_eab_kid
      acme_eab_hmac_key = var.acme_eab_hmac_key
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }

  depends_on = [
    arubacloud_securityrule.dbaas_mysql,
    arubacloud_databasegrant.wordpress,
  ]
}
