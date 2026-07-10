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
  description = "Short name used as part of all resource names (e.g. 'discourse')."
  type        = string
  default     = "discourse"

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
  description = "CloudServer flavor. CSO4A8 (4 vCPU / 8 GB) is the minimum for Discourse."
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. 100 GB recommended; the Docker bootstrap builds a full image."
  type        = number
  default     = 100

  validation {
    condition     = var.vm_disk_size_gb >= 40
    error_message = "vm_disk_size_gb must be at least 40 GB for Discourse."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
}

# ── Network access ────────────────────────────────────────────────────────────

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_cidr" {
  description = "CIDR allowed to reach the Discourse web server on ports 80 and 443."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Discourse configuration ───────────────────────────────────────────────────

variable "hostname" {
  description = "Domain name for Discourse (e.g. 'forum.example.com'). A real domain is strongly recommended for email delivery and SSL. Leave empty to use the VM's Elastic IP (HTTP only, no SSL)."
  type        = string
  default     = ""
}

variable "admin_email" {
  description = "Email address for the initial Discourse admin account. Must match a valid mailbox for email confirmation."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.admin_email))
    error_message = "admin_email must be a valid email address."
  }
}

variable "smtp_host" {
  description = "SMTP server address for outbound email (e.g. 'smtp.gmail.com')."
  type        = string
}

variable "smtp_port" {
  description = "SMTP server port (587 for STARTTLS, 465 for SSL)."
  type        = number
  default     = 587
}

variable "smtp_user" {
  description = "SMTP login username."
  type        = string
}

variable "smtp_password" {
  description = "SMTP login password."
  type        = string
  sensitive   = true
}
