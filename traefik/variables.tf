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
  default     = ""
}

variable "app_name" {
  type    = string
  default = "traefik"
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

variable "dashboard_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for Traefik dashboard (port 8080). Restrict to your IP in production."
}

variable "acme_email" {
  type        = string
  description = "Email address for Let's Encrypt ACME registration."
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.acme_email))
    error_message = "acme_email must be a valid email address."
  }
}

variable "traefik_version" {
  type        = string
  default     = "v3.2"
  description = "Traefik Docker image tag."
}

variable "enable_dashboard" {
  type        = bool
  default     = true
  description = "Enable the Traefik dashboard on port 8080."
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
