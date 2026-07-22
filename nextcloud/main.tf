locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["nextcloud", var.environment, "cloud-storage"]
  site_url    = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"

  # Escape passwords for PHP single-quoted string literals
  db_password_php = replace(replace(var.db_password, "\\", "\\\\"), "'", "\\'")
}

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "Nextcloud file sync (${var.environment})"
  tags        = local.tags
}

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

resource "arubacloud_database" "nextcloud" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  name       = "nextcloud"
}

resource "arubacloud_dbaasuser" "nextcloud" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  username   = "nextcloud"
  password   = var.db_password
}

resource "arubacloud_databasegrant" "nextcloud" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  database   = arubacloud_database.nextcloud.id
  user_id    = arubacloud_dbaasuser.nextcloud.id
  role       = "liteadmin"
}

# Random secret for Nextcloud's config.php
resource "random_password" "nc_secret" {
  length  = 32
  special = false
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
      db_host                      = module.network.dbaas_elastic_ip_address
      db_name                      = arubacloud_database.nextcloud.name
      db_user                      = arubacloud_dbaasuser.nextcloud.username
      db_password_php              = local.db_password_php
      nc_admin_user                = var.nc_admin_user
      nc_admin_password_b64        = base64encode(var.nc_admin_password)
      nc_admin_email               = var.nc_admin_email
      nc_secret                    = random_password.nc_secret.result
      site_url                     = local.site_url
      domain                       = var.domain
      module_network_vm_elastic_ip = module.network.vm_elastic_ip_address
      acme_eab_kid      = var.acme_eab_kid
      acme_eab_hmac_key = var.acme_eab_hmac_key
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }

  depends_on = [
    arubacloud_securityrule.dbaas_mysql,
    arubacloud_databasegrant.nextcloud,
  ]
}
