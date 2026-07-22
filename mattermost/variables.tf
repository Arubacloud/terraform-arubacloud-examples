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
  description = "Short name used as part of all resource names (e.g. 'mm')."
  type        = string
  default     = "mm"

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
  description = "CloudServer flavor. CSO4A8 (4 vCPU / 8 GB) is the recommended minimum for Mattermost."
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. Mattermost file attachments are stored here."
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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkHCyFqqdqzJw21x5i/MenBmYDhPQxXNrMjA0D98w3ZLlxbdrpoZ2NH8pupdVh5KM2vmDiOmsBKBVO2ivtkOXW+PrmrXi/g6KYw7uBZ82eCIi9rWclIJHpmM/kWeThjrGm9jlsz8Q5iq8TkPySuo7fo1ouIUVSBq9bexFl8+benOHopH39BqZ6WzrVVku+M6ZwDYR+88ffqEhWiVCZGhu3LLYWGXTaUsewOQOsbymx7R0jb/FboJ+rraMGRJYOlGAqgGt6VSeC9lOHSlgBuQVhrNxHI4HSxvCsqv7OtwIHbVs/VxEtWGwL6TO/iGzKX4hZ7G0+2BDiZ63IgTf+CEHbp9UaYU5xOC/f2iblgFLFwQnaTrrzDOuDWqcb/f8x56Ry7RV2bNvQ6XEPEB/x3+h09XU2CnyzdxQxDFclHxey+EIYqES4TQypqBc3W2FIKn8yDwyx45bg9rctvJ2PUA0gIlBzsPv29f3iGeIgXvwPlmHsT9ml8gToZ+HlvrhreAgWPMJA3c5goFxKIqp2LFNuejBQ+1Rdxx1J2rpAYEOtFbOixPPecsLz236YZRH4w+FdoGf9wPMcoaZOeqBN/sWmerWbPyaCLTUqRkNT0D0dmhkqG99PIkP7eJfJq/d+mdUNn4zTuQn3z5GKxgKrOszxNLHbRjfdFSOMaYkqWFga5Q=="
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "dbaas_flavor" {
  description = "Managed MySQL DBaaS flavor."
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
  description = "Password for the Mattermost MySQL user. Must be at least 16 characters and must not contain newlines."
  type        = string
  sensitive   = true
  default     = "K7m@P4z!L9"

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password must be at least 8 characters."
  }

  validation {
    condition     = !can(regex("\n", var.db_password))
    error_message = "db_password must not contain newline characters."
  }
}

# ── Mattermost application ────────────────────────────────────────────────────

variable "mattermost_version" {
  description = "Mattermost Team Edition version (e.g. '10.4.2'). See https://github.com/mattermost/mattermost/releases."
  type        = string
  default     = "10.4.2"
}

variable "domain" {
  description = "Custom domain for Mattermost (e.g. 'chat.example.com'). When set, Certbot provisions a Let's Encrypt TLS certificate. Leave empty to use the Elastic IP over HTTP."
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
