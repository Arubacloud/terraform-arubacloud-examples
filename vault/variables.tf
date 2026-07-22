# ── Provider credentials ───────────────────────────────────────────────────────

variable "arubacloud_client_id" {
  description = "ArubaCloud OAuth2 client ID."
  type        = string
  sensitive   = true
}

variable "arubacloud_client_secret" {
  description = "ArubaCloud OAuth2 client secret."
  type        = string
  sensitive   = true
}

# ── Deployment identity ────────────────────────────────────────────────────────

variable "app_name" {
  description = "Short name used as part of all resource names (e.g. 'vault')."
  type        = string
  default     = "vault"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,8}$", var.app_name))
    error_message = "app_name must be 2–8 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment label (e.g. 'prod', 'staging', 'dev')."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.environment))
    error_message = "environment must be 2–10 lowercase alphanumeric characters or hyphens."
  }
}

# ── Infrastructure ────────────────────────────────────────────────────────────

variable "location" {
  description = "ArubaCloud region (e.g. 'ITBG-Bergamo')."
  type        = string
  default     = "ITBG-Bergamo"
}

variable "zone" {
  description = "Availability zone within the region (e.g. 'ITBG-1')."
  type        = string
  default     = "ITBG-1"
}

variable "billing_period" {
  description = "Billing period for the Elastic IP ('Hour' or 'Month')."
  type        = string
  default     = "Hour"

  validation {
    condition     = contains(["Hour", "Month"], var.billing_period)
    error_message = "billing_period must be 'Hour' or 'Month'."
  }
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "vm_flavor" {
  description = "CloudServer flavor. CSO2A4 (2 vCPU / 4 GB) is sufficient for most Vault deployments."
  type        = string
  default     = "CSO2A4"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. Vault Raft data is stored here."
  type        = number
  default     = 30

  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "vm_disk_size_gb must be at least 20 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
  default     = ""
}

# ── Network access ────────────────────────────────────────────────────────────

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vault_cidr" {
  description = "CIDR allowed to reach the Vault API and UI on port 8200. Restrict to your IP or VPN range in production — Vault holds your secrets."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Vault configuration ───────────────────────────────────────────────────────

variable "vault_version" {
  description = "Vault release version to install from the HashiCorp APT repository (e.g. '1.18.4')."
  type        = string
  default     = "1.18.4"
}

variable "tls_san" {
  description = "Additional Subject Alternative Name for the self-signed TLS certificate (e.g. your domain or internal hostname). The Elastic IP is always included. Leave empty for IP-only."
  type        = string
  default     = ""
}
