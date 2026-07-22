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
  description = "Short name used as part of all resource names (e.g. 'kc')."
  type        = string
  default     = "kc"

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
  description = "CloudServer flavor. CSO4A8 (4 vCPU / 8 GB) is the recommended minimum for Keycloak with local PostgreSQL."
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 50

  validation {
    condition     = var.vm_disk_size_gb >= 30
    error_message = "vm_disk_size_gb must be at least 30 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
  default     = ""
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Keycloak application ──────────────────────────────────────────────────────

variable "keycloak_version" {
  description = "Keycloak release version (e.g. '26.0.7'). See https://github.com/keycloak/keycloak/releases."
  type        = string
  default     = "26.0.7"
}

variable "keycloak_admin" {
  description = "Keycloak initial admin username."
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak initial admin password. Must be at least 12 characters."
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"

  validation {
    condition     = length(var.keycloak_admin_password) >= 12
    error_message = "keycloak_admin_password must be at least 12 characters."
  }
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_password" {
  description = "Password for the Keycloak PostgreSQL user. Must be at least 16 characters and must not contain newlines."
  type        = string
  sensitive   = true
  default     = "ChangeMe1234!DbPass"

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }

  validation {
    condition     = !can(regex("\n", var.db_password))
    error_message = "db_password must not contain newline characters."
  }
}

# ── Domain / TLS ──────────────────────────────────────────────────────────────

variable "domain" {
  description = "Custom domain for Keycloak (e.g. 'auth.example.com'). When set, Certbot provisions a Let's Encrypt TLS certificate and Keycloak's hostname is configured to use it. Leave empty to use the Elastic IP over HTTP."
  type        = string
  default     = ""
}

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
