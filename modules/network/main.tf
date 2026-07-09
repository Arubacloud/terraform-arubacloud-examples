resource "arubacloud_vpc" "this" {
  name       = "${var.name_prefix}-vpc"
  location   = var.location
  project_id = var.project_id
  tags       = var.tags
}

resource "arubacloud_subnet" "this" {
  name       = "${var.name_prefix}-subnet"
  location   = var.location
  project_id = var.project_id
  vpc_id     = arubacloud_vpc.this.id
  type       = "Basic"
  tags       = var.tags
}

# ── VM security group ──────────────────────────────────────────────────────────

resource "arubacloud_securitygroup" "vm" {
  name       = "${var.name_prefix}-vm-sg"
  location   = var.location
  project_id = var.project_id
  vpc_id     = arubacloud_vpc.this.id
  tags       = var.tags

  depends_on = [arubacloud_subnet.this]
}

resource "arubacloud_securityrule" "vm_ingress" {
  for_each = var.vm_ingress_ports

  name              = "${var.name_prefix}-vm-${each.key}"
  location          = var.location
  project_id        = var.project_id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.vm.id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = each.value.port
    target = {
      kind  = "Ip"
      value = each.value.cidr
    }
  }
}

resource "arubacloud_securityrule" "vm_egress" {
  name              = "${var.name_prefix}-vm-egress"
  location          = var.location
  project_id        = var.project_id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.vm.id

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

resource "arubacloud_elasticip" "vm" {
  name           = "${var.name_prefix}-vm-eip"
  location       = var.location
  project_id     = var.project_id
  billing_period = var.billing_period
  tags           = var.tags
}

# ── DBaaS security group (optional) ───────────────────────────────────────────
# App-specific rules (e.g. MySQL port 3306 restricted to the VM IP) must be
# created in the calling module after the VM Elastic IP is known.

resource "arubacloud_securitygroup" "dbaas" {
  count = var.create_dbaas_network ? 1 : 0

  name       = "${var.name_prefix}-db-sg"
  location   = var.location
  project_id = var.project_id
  vpc_id     = arubacloud_vpc.this.id
  tags       = var.tags

  depends_on = [arubacloud_subnet.this]
}

resource "arubacloud_securityrule" "dbaas_egress" {
  count = var.create_dbaas_network ? 1 : 0

  name              = "${var.name_prefix}-db-egress"
  location          = var.location
  project_id        = var.project_id
  vpc_id            = arubacloud_vpc.this.id
  security_group_id = arubacloud_securitygroup.dbaas[0].id

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

resource "arubacloud_elasticip" "dbaas" {
  count = var.create_dbaas_network ? 1 : 0

  name           = "${var.name_prefix}-db-eip"
  location       = var.location
  project_id     = var.project_id
  billing_period = var.billing_period
  tags           = var.tags
}
