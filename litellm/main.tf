locals {
  name_prefix       = "${var.app_name}-${var.environment}"
  tags              = ["litellm", var.environment, "ai-ml"]
  master_key_b64    = base64encode(var.master_key)
  openai_key_b64    = base64encode(var.openai_api_key)
  anthropic_key_b64 = base64encode(var.anthropic_api_key)
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "arubacloud_project" "this" {
  name        = local.name_prefix
  description = "LiteLLM OpenAI-compatible LLM proxy (${var.environment})"
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
    ssh = { port = "22", cidr = var.ssh_cidr }
    api = { port = "4000", cidr = var.api_cidr }
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
      master_key_b64    = local.master_key_b64
      openai_key_b64    = local.openai_key_b64
      anthropic_key_b64 = local.anthropic_key_b64
      ollama_base_url   = var.ollama_base_url
      litellm_version   = var.litellm_version
    })
  }

  storage = {
    boot_volume_uri_ref = arubacloud_blockstorage.boot.uri
  }
}
