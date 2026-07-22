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
  description = "Short application name used as part of all resource names (e.g. 'wp')."
  type        = string
  default     = "wp"

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
  description = "Billing period for Elastic IPs and DBaaS ('Hour' or 'Month')."
  type        = string
  default     = "Hour"

  validation {
    condition     = contains(["Hour", "Month"], var.billing_period)
    error_message = "billing_period must be 'Hour' or 'Month'."
  }
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "vm_flavor" {
  description = "CloudServer flavor name. See https://api.arubacloud.com/docs/metadata/#cloudserver-flavors"
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Size of the boot disk in GB."
  type        = number
  default     = 40

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

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production (e.g. '203.0.113.42/32')."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "dbaas_flavor" {
  description = "Managed MySQL DBaaS flavor name."
  type        = string
  default     = "DBO2A8"
}

variable "db_storage_gb" {
  description = "Initial DBaaS storage size in GB."
  type        = number
  default     = 20

  validation {
    condition     = var.db_storage_gb >= 10
    error_message = "db_storage_gb must be at least 10 GB."
  }
}

variable "db_password" {
  description = "Password for the WordPress MySQL user. Must not contain newlines."
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

# ── WordPress application ─────────────────────────────────────────────────────

variable "wp_admin_user" {
  description = "WordPress admin username."
  type        = string
  default     = "admin"

  validation {
    condition     = var.wp_admin_user != "admin" || true # allow admin but document it
    error_message = "Consider using a non-default admin username for better security."
  }
}

variable "wp_admin_password" {
  description = "WordPress admin password. Must not contain newlines."
  type        = string
  sensitive   = true
  default     = "ChangeMe123!WpAdmin"

  validation {
    condition     = length(var.wp_admin_password) >= 16
    error_message = "wp_admin_password must be at least 16 characters."
  }

  validation {
    condition     = !can(regex("\n", var.wp_admin_password))
    error_message = "wp_admin_password must not contain newline characters."
  }
}

variable "wp_admin_email" {
  description = "WordPress admin email address. Also used for Let's Encrypt registration."
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.wp_admin_email))
    error_message = "wp_admin_email must be a valid email address."
  }
}

variable "wp_title" {
  description = "WordPress site title."
  type        = string
  default     = "My WordPress Site"
}

variable "domain" {
  description = "Custom domain name for the site (e.g. 'blog.example.com'). When set, Certbot provisions a Let's Encrypt TLS certificate. Leave empty to use the Elastic IP over HTTP."
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
