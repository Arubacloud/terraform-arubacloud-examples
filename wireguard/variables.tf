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

variable "app_name" {
  description = "Short name used in resource names (e.g. 'wg')."
  type        = string
  default     = "wg"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,8}$", var.app_name))
    error_message = "app_name must be 2–8 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment label (e.g. 'prod', 'dev')."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.environment))
    error_message = "environment must be 2–10 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "ArubaCloud region."
  type        = string
  default     = "ITBG-Bergamo"
}

variable "zone" {
  description = "Availability zone within the region."
  type        = string
  default     = "ITBG-1"
}

variable "billing_period" {
  description = "Billing period ('Hour' or 'Month')."
  type        = string
  default     = "Hour"

  validation {
    condition     = contains(["Hour", "Month"], var.billing_period)
    error_message = "billing_period must be 'Hour' or 'Month'."
  }
}

variable "vm_flavor" {
  description = "CloudServer flavor. See https://api.arubacloud.com/docs/metadata/#cloudserver-flavors"
  type        = string
  default     = "CSO2A4"
}

variable "vm_image" {
  description = "Boot disk image (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. 20 GB is sufficient for a VPN server."
  type        = number
  default     = 20

  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "vm_disk_size_gb must be at least 20 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content (e.g. contents of ~/.ssh/id_ed25519.pub)."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed for SSH access. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpn_port" {
  description = "UDP port WireGuard listens on."
  type        = number
  default     = 51820

  validation {
    condition     = var.vpn_port > 0 && var.vpn_port < 65536
    error_message = "vpn_port must be a valid UDP port (1–65535)."
  }
}

variable "vpn_server_address" {
  description = "WireGuard interface address on the server (CIDR notation). Clients get IPs from this subnet."
  type        = string
  default     = "10.8.0.1/24"
}

variable "dns_servers" {
  description = "DNS servers pushed to WireGuard clients."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}
