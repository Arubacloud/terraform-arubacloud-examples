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
  description = "Short application name used as part of all resource names (e.g. 'forgejo')."
  type        = string
  default     = "forgejo"

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
  description = "CloudServer flavor name. CSO2A4 (2 vCPU / 4 GB) is the recommended minimum for Forgejo."
  type        = string
  default     = "CSO2A4"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Size of the boot disk in GB. Repositories are stored here when using SQLite; size accordingly for larger installations."
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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkHCyFqqdqzJw21x5i/MenBmYDhPQxXNrMjA0D98w3ZLlxbdrpoZ2NH8pupdVh5KM2vmDiOmsBKBVO2ivtkOXW+PrmrXi/g6KYw7uBZ82eCIi9rWclIJHpmM/kWeThjrGm9jlsz8Q5iq8TkPySuo7fo1ouIUVSBq9bexFl8+benOHopH39BqZ6WzrVVku+M6ZwDYR+88ffqEhWiVCZGhu3LLYWGXTaUsewOQOsbymx7R0jb/FboJ+rraMGRJYOlGAqgGt6VSeC9lOHSlgBuQVhrNxHI4HSxvCsqv7OtwIHbVs/VxEtWGwL6TO/iGzKX4hZ7G0+2BDiZ63IgTf+CEHbp9UaYU5xOC/f2iblgFLFwQnaTrrzDOuDWqcb/f8x56Ry7RV2bNvQ6XEPEB/x3+h09XU2CnyzdxQxDFclHxey+EIYqES4TQypqBc3W2FIKn8yDwyx45bg9rctvJ2PUA0gIlBzsPv29f3iGeIgXvwPlmHsT9ml8gToZ+HlvrhreAgWPMJA3c5goFxKIqp2LFNuejBQ+1Rdxx1J2rpAYEOtFbOixPPecsLz236YZRH4w+FdoGf9wPMcoaZOeqBN/sWmerWbPyaCLTUqRkNT0D0dmhkqG99PIkP7eJfJq/d+mdUNn4zTuQn3z5GKxgKrOszxNLHbRjfdFSOMaYkqWFga5Q=="
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production (e.g. '203.0.113.42/32')."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "enable_mysql" {
  description = "When true, provisions a Managed MySQL 8.0 DBaaS instance. When false (default), Forgejo uses an SQLite database stored on the boot disk — lower cost and simpler for small teams."
  type        = bool
  default     = false
}

variable "dbaas_flavor" {
  description = "Managed MySQL DBaaS flavor. Only used when enable_mysql = true."
  type        = string
  default     = "DBO2A8"
}

variable "db_storage_gb" {
  description = "Initial DBaaS storage in GB. Only used when enable_mysql = true."
  type        = number
  default     = 20

  validation {
    condition     = var.db_storage_gb >= 10
    error_message = "db_storage_gb must be at least 10 GB."
  }
}

variable "db_password" {
  description = "Password for the Forgejo MySQL user. Required when enable_mysql = true. Must be at least 16 characters and must not contain newlines."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.db_password == "" || length(var.db_password) >= 8
    error_message = "db_password must be at least 8 characters when set."
  }

  validation {
    condition     = !can(regex("\n", var.db_password))
    error_message = "db_password must not contain newline characters."
  }
}

# ── Forgejo application ───────────────────────────────────────────────────────

variable "forgejo_version" {
  description = "Forgejo release version to install (e.g. '9.0.3'). Check https://forgejo.org/releases/ for the latest release."
  type        = string
  default     = "9.0.3"
}

variable "domain" {
  description = "Custom domain for the Forgejo instance (e.g. 'git.example.com'). When set, Certbot provisions a Let's Encrypt TLS certificate and nginx terminates HTTPS. Leave empty to use the Elastic IP over HTTP."
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
