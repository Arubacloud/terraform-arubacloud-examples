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
  default = "vw"
  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.app_name))
    error_message = "app_name must be 2–10 lowercase alphanumeric characters or hyphens."
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
  default     = "CSO1A2"
  description = "CloudServer flavor."
}

variable "vm_image" {
  type        = string
  default     = "LU22-001"
  description = "Boot image."
}

variable "vm_disk_size_gb" {
  type    = number
  default = 20
  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "Minimum 20 GB."
  }
  description = "Boot disk size in GB."
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for SSH."
}

variable "domain" {
  type        = string
  default     = ""
  description = "Domain name for HTTPS (e.g. 'vault.example.com'). Required for mobile Bitwarden clients. Set DNS A record to the VM IP before apply."
}

variable "admin_token" {
  type        = string
  sensitive   = true
  description = "Vaultwarden admin panel token. Leave empty to disable the admin panel."
  default     = ""
}

variable "admin_email" {
  type        = string
  description = "Email address for Let's Encrypt registration (required when domain is set)."
  default     = ""
}

variable "vaultwarden_version" {
  type        = string
  default     = "latest"
  description = "Vaultwarden Docker image tag."
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
