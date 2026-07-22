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
  description = "Short name used as part of all resource names (e.g. 'sonar')."
  type        = string
  default     = "sonar"

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
  description = "CloudServer flavor. CSO4A8 (4 vCPU / 8 GB) is the minimum; CSO8A16 is recommended for larger teams."
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. SonarQube analysis data and Elasticsearch indices are stored here."
  type        = number
  default     = 80

  validation {
    condition     = var.vm_disk_size_gb >= 40
    error_message = "vm_disk_size_gb must be at least 40 GB for SonarQube."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
  default     = ""
}

# ── Network access ────────────────────────────────────────────────────────────

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22."
  type        = string
  default     = "0.0.0.0/0"
}

variable "sonar_cidr" {
  description = "CIDR allowed to reach the SonarQube web interface on port 9000. Restrict to your office or VPN range in production."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_password" {
  description = "Password for the SonarQube PostgreSQL user. Must be at least 16 characters and must not contain newlines."
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

# ── SonarQube application ─────────────────────────────────────────────────────

variable "sonarqube_version" {
  description = "SonarQube Community Edition version string including build number (e.g. '10.7.0.96327'). See https://www.sonarsource.com/products/sonarqube/downloads/historical-downloads/."
  type        = string
  default     = "10.7.0.96327"
}
