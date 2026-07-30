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
  description = "Short name used as part of all resource names."
  type        = string
  default     = "jupyter"

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

# ── Infrastructure ─────────────────────────────────────────────────────────────

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
  description = "CloudServer flavor. CSO2A4 (2 vCPU / 4 GB) suits most notebook workloads; upgrade to CSO4A8 for compute-heavy analysis."
  type        = string
  default     = "CSO2A4"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. Increase for large datasets or many notebook environments."
  type        = number
  default     = 40

  validation {
    condition     = var.vm_disk_size_gb >= 40
    error_message = "vm_disk_size_gb must be at least 40 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content (e.g. contents of ~/.ssh/id_ed25519.pub)."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

# ── JupyterLab ────────────────────────────────────────────────────────────────

variable "jupyter_password" {
  description = "Password to access JupyterLab. Min 8 characters, no newlines."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jupyter_password) >= 8 && !can(regex("\n", var.jupyter_password))
    error_message = "jupyter_password must be at least 8 characters and must not contain newlines."
  }
}

variable "domain" {
  description = "Custom domain for HTTPS (e.g. 'notebooks.example.com'). Leave empty to use the Elastic IP over HTTP."
  type        = string
  default     = ""
}

# ── ACME (optional) ───────────────────────────────────────────────────────────

variable "acme_eab_kid" {
  description = "Optional Actalis ACME External Account Binding key ID. Leave empty to use Let's Encrypt."
  type        = string
  default     = ""
  sensitive   = true
}

variable "acme_eab_hmac_key" {
  description = "Optional Actalis ACME External Account Binding HMAC key. Required when acme_eab_kid is set."
  type        = string
  default     = ""
  sensitive   = true
}
