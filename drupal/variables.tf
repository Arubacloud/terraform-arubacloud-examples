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
  description = "Short name used as part of all resource names (e.g. 'drupal')."
  type        = string
  default     = "drupal"

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
  description = "CloudServer flavor. CSO4A8 (4 vCPU / 8 GB) recommended; Composer needs memory."
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
  default     = 40

  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "vm_disk_size_gb must be at least 20 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzZB11JRKjbPO/1wAtJ/9+/xQtndp61EWo1T2GhIVJO0eiBbUoufdhX989hAyE0JlyGjvDloe0c8S1sK8NAeLEx/jaKwsbHMQGxkusoBFUQDGWlREsHRHn7/78Wbra45ZJi6r9uizao7HDtoq0GCB6DfleOpKMLjOLHv9NaH0Hm119ZztHIqrmWmc25e27Evy3Nht9hX0Yb/OsEWcWBKhVv6SXGdB7SCXKYIPj7357bLpb4SdW9RxQA40bjlEFtPSqZ3HNXZ7yrUZXQWtrVkpia51nR088Jz0rMlmLgH+RPTDtj8CcI/E6QgsKXfrlxswbl3cT41qZVHi0+hNxE9vg+MSAVuYKgyWWFU7qlQCvmKmDPDjivBaFn7Aaz9qw71brpIeNXRwNiEbHy2+2+A0X8iIbc1Ca3RdVQ2rBLRXQDhNMi2syJkyty0ZTiLSNt+rhl4JgFZBz88q7b34MezNNNP7HX4oG+XpwjUe4KzDjk8EbBfxiPlLy7xkBioxRe+E="
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production."
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
  description = "Password for the Drupal MySQL user. Must not contain newlines."
  type        = string
  sensitive   = true
  default     = "K7m@P4z!L9xQ8rWs"

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }

  validation {
    condition     = !can(regex("\n", var.db_password))
    error_message = "db_password must not contain newline characters."
  }
}

# ── Drupal application ────────────────────────────────────────────────────────

variable "site_name" {
  description = "Drupal site name displayed in the browser title and admin panel."
  type        = string
  default     = "My Drupal Site"
}

variable "admin_user" {
  description = "Drupal admin username."
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Drupal admin password. Must not contain newlines."
  type        = string
  sensitive   = true
  default     = "K7m@P4z!L9xQ8rWs"

  validation {
    condition     = length(var.admin_password) >= 16
    error_message = "admin_password must be at least 16 characters."
  }

  validation {
    condition     = !can(regex("\n", var.admin_password))
    error_message = "admin_password must not contain newline characters."
  }
}

variable "admin_email" {
  description = "Drupal admin email address. Also used for Let's Encrypt registration."
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.admin_email))
    error_message = "admin_email must be a valid email address."
  }
}

variable "domain" {
  description = "Optional custom domain for the site (e.g. 'drupal.example.com'). When set, Certbot provisions a Let's Encrypt certificate. Leave empty to use the Elastic IP over HTTP."
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
