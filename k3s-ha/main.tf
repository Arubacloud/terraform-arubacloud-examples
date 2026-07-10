locals {
  name_prefix = "${var.app_name}-${var.environment}"
  tags        = ["k3s-ha", var.environment, "kubernetes"]
  token_b64   = base64encode(var.k3s_token)

  # Node names
  node_names = ["node-1", "node-2", "node-3"]

  # Datastore DSN for k3s external MySQL backend (mysql:// scheme required by kine)
  datastore_dsn     = "mysql://${var.db_user}:${var.db_password}@tcp(${var.db_host}:${var.db_port})/${var.db_name}"
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
      k3s_version       = var.k3s_version
      token_b64         = local.token_b64
      datastore_dsn_b64 = local.datastore_dsn_b64
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.nodes[each.key].uri
  }
}
