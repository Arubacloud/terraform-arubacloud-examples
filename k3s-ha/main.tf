locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["k3s-ha", var.environment, "kubernetes"]
  token_b64   = base64encode(var.k3s_token)

  # Node names
  node_names = ["node-1", "node-2", "node-3"]

  # Datastore DSN — host is the provisioned DBaaS elastic IP
  datastore_dsn     = "mysql://${var.db_user}:${var.db_password}@tcp(${arubacloud_elasticip.dbaas.address}:3306)/${var.db_name}"
  datastore_dsn_b64 = base64encode(local.datastore_dsn)
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "k3s HA Kubernetes cluster — 3 control-plane nodes (${var.environment})"
  tags        = local.tags
}

# ── Networking (shared VPC / subnet / security group) ─────────────────────────

resource "arubacloud_vpc" "this" {
  name       = "${local.name_prefix}-vpc"
  location   = var.location
  project_id = arubacloud_project.this.id
  tags       = local.tags
}

resource "arubacloud_subnet" "this" {
  name       = "${local.name_prefix}-subnet"
  location   = var.location
  project_id = arubacloud_project.this.id
  vpc_id     = arubacloud_vpc.this.id
  type       = "Basic"
  tags       = local.tags
}

resource "arubacloud_securitygroup" "this" {
  name       = "${local.name_prefix}-sg"
  location   = var.location
  project_id = arubacloud_project.this.id
  vpc_id     = arubacloud_vpc.this.id
  tags       = local.tags

  depends_on = [arubacloud_subnet.this]
}

resource "arubacloud_securityrule" "ssh" {
  name              = "${local.name_prefix}-ssh"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.this.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "22"
    target = {
      kind  = "Ip"
      value = var.ssh_cidr
    }
  }
}

resource "arubacloud_securityrule" "api" {
  name              = "${local.name_prefix}-api"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.this.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "6443"
    target = {
      kind  = "Ip"
      value = var.api_cidr
    }
  }
}

resource "arubacloud_securityrule" "http" {
  name              = "${local.name_prefix}-http"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.this.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "80"
    target = {
      kind  = "Ip"
      value = "0.0.0.0/0"
    }
  }
}

resource "arubacloud_securityrule" "https" {
  name              = "${local.name_prefix}-https"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.this.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "443"
    target = {
      kind  = "Ip"
      value = "0.0.0.0/0"
    }
  }
}

resource "arubacloud_securityrule" "egress" {
  name              = "${local.name_prefix}-egress"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.this.id

  properties = {
    direction = "Egress"
    protocol  = "ANY"
    port      = "*"
    target = {
      kind  = "Ip"
      value = "0.0.0.0/0"
    }
  }
}

# ── Elastic IPs (one per node) ────────────────────────────────────────────────

resource "arubacloud_elasticip" "nodes" {
  for_each = toset(local.node_names)

  name           = "${local.name_prefix}-${each.key}-eip"
  location       = var.location
  project_id     = arubacloud_project.this.id
  billing_period = var.billing_period
  tags           = local.tags
}

# ── DBaaS network ────────────────────────────────────────────────────────────

resource "arubacloud_elasticip" "dbaas" {
  name           = "${local.name_prefix}-dbaas-eip"
  location       = var.location
  project_id     = arubacloud_project.this.id
  billing_period = var.billing_period
  tags           = local.tags
}

resource "arubacloud_securitygroup" "dbaas" {
  name       = "${local.name_prefix}-dbaas-sg"
  location   = var.location
  project_id = arubacloud_project.this.id
  vpc_id     = arubacloud_vpc.this.id
  tags       = local.tags

  depends_on = [arubacloud_subnet.this]
}

resource "arubacloud_securityrule" "dbaas_egress" {
  name              = "${local.name_prefix}-dbaas-egress"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.dbaas.id

  properties = {
    direction = "Egress"
    protocol  = "ANY"
    port      = "*"
    target = {
      kind  = "Ip"
      value = "0.0.0.0/0"
    }
  }
}

# Allow each control-plane node to reach MySQL 3306
resource "arubacloud_securityrule" "dbaas_mysql" {
  for_each = arubacloud_elasticip.nodes

  name              = "${local.name_prefix}-dbaas-mysql-${each.key}"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.dbaas.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "3306"
    target = {
      kind  = "Ip"
      value = "${each.value.address}/32"
    }
  }
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
    vpc_uri_ref            = arubacloud_vpc.this.uri
    subnet_uri_ref         = arubacloud_subnet.this.uri
    security_group_uri_ref = arubacloud_securitygroup.dbaas.uri
    elastic_ip_uri_ref     = arubacloud_elasticip.dbaas.uri
  }

  billing_period = var.billing_period
}

resource "arubacloud_database" "k3s" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  name       = var.db_name
}

resource "arubacloud_dbaasuser" "k3s" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  username   = var.db_user
  password   = var.db_password
}

resource "arubacloud_databasegrant" "k3s" {
  project_id = arubacloud_project.this.id
  dbaas_id   = arubacloud_dbaas.this.id
  database   = arubacloud_database.k3s.id
  user_id    = arubacloud_dbaasuser.k3s.id
  role       = "liteadmin"
}

# ── SSH key pair (shared) ─────────────────────────────────────────────────────

resource "arubacloud_keypair" "this" {
  name       = "${local.name_prefix}-keypair"
  location   = var.location
  project_id = arubacloud_project.this.id
  value      = var.ssh_public_key
}

# ── Boot volumes (one per node) ───────────────────────────────────────────────

resource "arubacloud_blockstorage" "nodes" {
  for_each = toset(local.node_names)

  name           = "${local.name_prefix}-${each.key}-boot"
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

# ── Cloud Servers (3 control-plane nodes) ─────────────────────────────────────

resource "arubacloud_cloudserver" "nodes" {
  for_each = toset(local.node_names)

  name       = "${local.name_prefix}-${each.key}"
  location   = var.location
  project_id = arubacloud_project.this.id
  zone       = var.zone
  tags       = local.tags

  network = {
    vpc_uri_ref            = arubacloud_vpc.this.uri
    elastic_ip_uri_ref     = arubacloud_elasticip.nodes[each.key].uri
    subnet_uri_refs        = [arubacloud_subnet.this.uri]
    securitygroup_uri_refs = [arubacloud_securitygroup.this.uri]
  }

  settings = {
    flavor_name      = var.vm_flavor
    key_pair_uri_ref = arubacloud_keypair.this.uri
    user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
      node_name         = each.key
      node_public_ip    = arubacloud_elasticip.nodes[each.key].address
      k3s_version       = var.k3s_version
      token_b64         = local.token_b64
      datastore_dsn_b64 = local.datastore_dsn_b64
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.nodes[each.key].uri
  }

  depends_on = [arubacloud_databasegrant.k3s]
}
