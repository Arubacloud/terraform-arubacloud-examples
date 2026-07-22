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
  description = "Short name used as part of all resource names (e.g. 'wazuh')."
  type        = string
  default     = "wazuh"

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
  description = "CloudServer flavor. CSO8A16 (8 vCPU / 16 GB) is the minimum for Wazuh all-in-one; the OpenSearch indexer requires substantial RAM."
  type        = string
  default     = "CSO8A16"
}

variable "vm_image" {
  description = "Boot disk image ID (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. 200 GB recommended for log retention."
  type        = number
  default     = 200

  validation {
    condition     = var.vm_disk_size_gb >= 50
    error_message = "vm_disk_size_gb must be at least 50 GB for Wazuh."
  }
}

variable "ssh_public_key" {
  description = "SSH public key value (the content of your id_rsa.pub or id_ed25519.pub)."
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzZB11JRKjbPO/1wAtJ/9+/xQtndp61EWo1T2GhIVJO0eiBbUoufdhX989hAyE0JlyGjvDloe0c8S1sK8NAeLEx/jaKwsbHMQGxkusoBFUQDGWlREsHRHn7/78Wbra45ZJi6r9uizao7HDtoq0GCB6DfleOpKMLjOLHv9NaH0Hm119ZztHIqrmWmc25e27Evy3Nht9hX0Yb/OsEWcWBKhVv6SXGdB7SCXKYIPj7357bLpb4SdW9RxQA40bjlEFtPSqZ3HNXZ7yrUZXQWtrVkpia51nR088Jz0rMlmLgH+RPTDtj8CcI/E6QgsKXfrlxswbl3cT41qZVHi0+hNxE9vg+MSAVuYKgyWWFU7qlQCvmKmDPDjivBaFn7Aaz9qw71brpIeNXRwNiEbHy2+2+A0X8iIbc1Ca3RdVQ2rBLRXQDhNMi2syJkyty0ZTiLSNt+rhl4JgFZBz88q7b34MezNNNP7HX4oG+XpwjUe4KzDjk8EbBfxiPlLy7xkBioxRe+E="
}

# ── Network access ────────────────────────────────────────────────────────────

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH port 22. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the Wazuh dashboard on port 443. Restrict to your management IP."
  type        = string
  default     = "0.0.0.0/0"
}

variable "agent_cidr" {
  description = "CIDR from which Wazuh agents connect on ports 1514 and 1515. Should match your monitored infrastructure CIDR."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Wazuh configuration ───────────────────────────────────────────────────────

variable "admin_password" {
  description = "Password for the Wazuh dashboard admin user (min 8 characters, must contain uppercase, lowercase, digit, and special character)."
  type        = string
  sensitive   = true
  default     = "K7m@P4z!L9xQ8rWs"

  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "admin_password must be at least 8 characters."
  }
}
