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
  description = "Short name used in resource names."
  type        = string
  default     = "docker"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.app_name))
    error_message = "app_name must be 2–10 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment label."
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
  description = "CloudServer flavor."
  type        = string
  default     = "CSO2A4"
}

variable "vm_image" {
  description = "Boot disk image (Ubuntu 22.04 LTS)."
  type        = string
  default     = "LU22-001"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB. Increase if you plan to pull large Docker images."
  type        = number
  default     = 50

  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "vm_disk_size_gb must be at least 20 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzZB11JRKjbPO/1wAtJ/9+/xQtndp61EWo1T2GhIVJO0eiBbUoufdhX989hAyE0JlyGjvDloe0c8S1sK8NAeLEx/jaKwsbHMQGxkusoBFUQDGWlREsHRHn7/78Wbra45ZJi6r9uizao7HDtoq0GCB6DfleOpKMLjOLHv9NaH0Hm119ZztHIqrmWmc25e27Evy3Nht9hX0Yb/OsEWcWBKhVv6SXGdB7SCXKYIPj7357bLpb4SdW9RxQA40bjlEFtPSqZ3HNXZ7yrUZXQWtrVkpia51nR088Jz0rMlmLgH+RPTDtj8CcI/E6QgsKXfrlxswbl3cT41qZVHi0+hNxE9vg+MSAVuYKgyWWFU7qlQCvmKmDPDjivBaFn7Aaz9qw71brpIeNXRwNiEbHy2+2+A0X8iIbc1Ca3RdVQ2rBLRXQDhNMi2syJkyty0ZTiLSNt+rhl4JgFZBz88q7b34MezNNNP7HX4oG+XpwjUe4KzDjk8EbBfxiPlLy7xkBioxRe+E="
}

variable "ssh_cidr" {
  description = "CIDR allowed for SSH access. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "docker_users" {
  description = "Additional Linux users to add to the docker group (beyond 'ubuntu')."
  type        = list(string)
  default     = []
}
