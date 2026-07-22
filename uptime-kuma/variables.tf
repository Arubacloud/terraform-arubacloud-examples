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
  default = "kuma"
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
  description = "Boot image (Ubuntu 22.04)."
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
  description = "CIDR for SSH — restrict to your IP."
}

variable "admin_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for Uptime Kuma web UI (port 3001). Restrict to your IP."
}

variable "kuma_port" {
  type        = number
  default     = 3001
  description = "Port Uptime Kuma listens on."
}
