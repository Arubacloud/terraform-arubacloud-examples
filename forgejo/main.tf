locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["forgejo", var.environment, "git"]
  ssh_host    = var.domain != "" ? var.domain : module.network.vm_elastic_ip_address
  base_url    = var.domain != "" ? "https://${var.domain}" : "http://${module.network.vm_elastic_ip_address}"
  server_name = var.domain != "" ? var.domain : "_"
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "Forgejo self-hosted Git (${var.environment})"
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
  create_dbaas_network = var.enable_mysql

  vm_ingress_ports = {
    ssh     = { port = "22", cidr = var.ssh_cidr }
    http    = { port = "80", cidr = "0.0.0.0/0" }
    https   = { port = "443", cidr = "0.0.0.0/0" }
    git_ssh = { port = "2222", cidr = "0.0.0.0/0" }
  }
}

resource "arubacloud_securityrule" "dbaas_mysql" {
  count = var.enable_mysql ? 1 : 0

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

# ── Managed MySQL (optional) ──────────────────────────────────────────────────

resource "arubacloud_dbaas" "this" {
  count = var.enable_mysql ? 1 : 0

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

resource "arubacloud_database" "forgejo" {
  count = var.enable_mysql ? 1 : 0

  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this[0].id
  name       = "forgejo"
}

resource "arubacloud_dbaasuser" "forgejo" {
  count = var.enable_mysql ? 1 : 0

  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this[0].id
  username   = "forgejo"
  password   = var.db_password
}

resource "arubacloud_databasegrant" "forgejo" {
  count = var.enable_mysql ? 1 : 0

  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this[0].id
  database   = arubacloud_database.forgejo[0].id
  user_id    = arubacloud_dbaasuser.forgejo[0].id
  role       = "liteadmin"
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
      enable_mysql    = var.enable_mysql
      db_host         = var.enable_mysql ? module.network.dbaas_elastic_ip_address : ""
      db_name         = var.enable_mysql ? arubacloud_database.forgejo[0].name : ""
      db_user         = var.enable_mysql ? arubacloud_dbaasuser.forgejo[0].username : ""
      db_pass_b64     = var.enable_mysql ? base64encode(var.db_password) : ""
      forgejo_version = var.forgejo_version
      base_url        = local.base_url
      ssh_host        = local.ssh_host
      server_name     = local.server_name
      domain          = var.domain
      acme_eab_kid      = var.acme_eab_kid
      acme_eab_hmac_key = var.acme_eab_hmac_key
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }

  depends_on = [
    arubacloud_securityrule.dbaas_mysql,
    arubacloud_databasegrant.forgejo,
  ]
}
