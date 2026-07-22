variable "arubacloud_client_id" {
  type        = string
  sensitive   = true
  description = "ArubaCloud OAuth2 client ID."
}

variable "arubacloud_client_secret" {
  type        = string
  sensitive   = true
  description = "ArubaCloud OAuth2 client secret."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content."
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkHCyFqqdqzJw21x5i/MenBmYDhPQxXNrMjA0D98w3ZLlxbdrpoZ2NH8pupdVh5KM2vmDiOmsBKBVO2ivtkOXW+PrmrXi/g6KYw7uBZ82eCIi9rWclIJHpmM/kWeThjrGm9jlsz8Q5iq8TkPySuo7fo1ouIUVSBq9bexFl8+benOHopH39BqZ6WzrVVku+M6ZwDYR+88ffqEhWiVCZGhu3LLYWGXTaUsewOQOsbymx7R0jb/FboJ+rraMGRJYOlGAqgGt6VSeC9lOHSlgBuQVhrNxHI4HSxvCsqv7OtwIHbVs/VxEtWGwL6TO/iGzKX4hZ7G0+2BDiZ63IgTf+CEHbp9UaYU5xOC/f2iblgFLFwQnaTrrzDOuDWqcb/f8x56Ry7RV2bNvQ6XEPEB/x3+h09XU2CnyzdxQxDFclHxey+EIYqES4TQypqBc3W2FIKn8yDwyx45bg9rctvJ2PUA0gIlBzsPv29f3iGeIgXvwPlmHsT9ml8gToZ+HlvrhreAgWPMJA3c5goFxKIqp2LFNuejBQ+1Rdxx1J2rpAYEOtFbOixPPecsLz236YZRH4w+FdoGf9wPMcoaZOeqBN/sWmerWbPyaCLTUqRkNT0D0dmhkqG99PIkP7eJfJq/d+mdUNn4zTuQn3z5GKxgKrOszxNLHbRjfdFSOMaYkqWFga5Q=="
}

variable "app_name" {
  type    = string
  default = "nc"
  validation {
    condition     = can(regex("^[a-z0-9-]{2,8}$", var.app_name))
    error_message = "app_name must be 2–8 lowercase alphanumeric characters or hyphens."
  }
  description = "Short name used in resource names."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment label."
}

variable "location" {
  type        = string
  default     = "ITBG-Bergamo"
  description = "ArubaCloud region."
}

variable "zone" {
  type        = string
  default     = "ITBG-1"
  description = "Availability zone."
}

variable "billing_period" {
  type        = string
  default     = "Hour"
  description = "'Hour' or 'Month'."
}

variable "vm_flavor" {
  type        = string
  default     = "CSO4A8"
  description = "CloudServer flavor. Nextcloud needs at least 4 vCPU / 8 GB."
}

variable "vm_image" {
  type        = string
  default     = "LU22-001"
  description = "Boot image."
}

variable "vm_disk_size_gb" {
  type    = number
  default = 80
  validation {
    condition     = var.vm_disk_size_gb >= 40
    error_message = "Minimum 40 GB for Nextcloud."
  }
  description = "Boot disk size. Users' files are stored here — size accordingly."
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for SSH."
}

variable "dbaas_flavor" {
  type        = string
  default     = "DBO2A8"
  description = "Managed MySQL DBaaS flavor."
}

variable "db_storage_gb" {
  type        = number
  default     = 20
  description = "DBaaS initial storage in GB."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "MySQL password for the Nextcloud database user. Min 16 chars, no newlines."
  default     = "K7m@P4z!L9"
  validation {
    condition     = length(var.db_password) >= 8 && !can(regex("\n", var.db_password))
    error_message = "db_password must be at least 8 characters and must not contain newlines."
  }
}

variable "nc_admin_user" {
  type        = string
  default     = "ncadmin"
  description = "Nextcloud admin username."
}

variable "nc_admin_password" {
  type        = string
  sensitive   = true
  description = "Nextcloud admin password. Min 16 chars, no newlines."
  default     = "K7m@P4z!L9"
  validation {
    condition     = length(var.nc_admin_password) >= 8 && !can(regex("\n", var.nc_admin_password))
    error_message = "nc_admin_password must be at least 8 characters and must not contain newlines."
  }
}

variable "nc_admin_email" {
  type        = string
  description = "Nextcloud admin email."
  default     = "admin@example.com"
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.nc_admin_email))
    error_message = "nc_admin_email must be a valid email address."
  }
}

variable "domain" {
  type        = string
  default     = ""
  description = "Custom domain for HTTPS (e.g. 'cloud.example.com'). Recommended for production. DNS must resolve to the Elastic IP before apply."
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
