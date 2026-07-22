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
  description = "Short name used as part of all resource names (e.g. 'k3sha')."
  type        = string
  default     = "k3sha"

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
  description = "Billing period for Elastic IPs ('Hour' or 'Month')."
  type        = string
  default     = "Hour"

  validation {
    condition     = contains(["Hour", "Month"], var.billing_period)
    error_message = "billing_period must be 'Hour' or 'Month'."
  }
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "vm_flavor" {
  description = "CloudServer flavor for each control-plane node. CSO4A8 (4 vCPU / 8 GB) is recommended."
  type        = string
  default     = "CSO4A8"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB per node."
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
  default     = ""
}

# ── Network access ────────────────────────────────────────────────────────────

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22 on all nodes. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "api_cidr" {
  description = "CIDR allowed to reach the k3s API server on port 6443. Restrict to your admin workstation or VPN."
  type        = string
  default     = "0.0.0.0/0"
}

# ── k3s configuration ─────────────────────────────────────────────────────────

variable "k3s_version" {
  description = "k3s version to install (e.g. 'v1.32.0+k3s1'). Use 'latest' for the current stable release."
  type        = string
  default     = "latest"
}

variable "k3s_token" {
  description = "Shared cluster token for node authentication. Generate with: openssl rand -hex 32"
  type        = string
  sensitive   = true
  default     = "ChangeMe1234!K3sToken"

  validation {
    condition     = length(var.k3s_token) >= 16
    error_message = "k3s_token must be at least 16 characters."
  }
}

# ── External MySQL datastore ──────────────────────────────────────────────────

variable "db_host" {
  description = "MySQL 8.0 database host (DBaaS endpoint or external server)."
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "MySQL database port."
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "MySQL database name for k3s datastore."
  type        = string
  default     = "k3s"
}

variable "db_user" {
  description = "MySQL database username."
  type        = string
  default     = "k3s"
}

variable "db_password" {
  description = "MySQL database password."
  type        = string
  sensitive   = true
  default     = "ChangeMe1234!DbPass"
}
