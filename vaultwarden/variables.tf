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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzZB11JRKjbPO/1wAtJ/9+/xQtndp61EWo1T2GhIVJO0eiBbUoufdhX989hAyE0JlyGjvDloe0c8S1sK8NAeLEx/jaKwsbHMQGxkusoBFUQDGWlREsHRHn7/78Wbra45ZJi6r9uizao7HDtoq0GCB6DfleOpKMLjOLHv9NaH0Hm119ZztHIqrmWmc25e27Evy3Nht9hX0Yb/OsEWcWBKhVv6SXGdB7SCXKYIPj7357bLpb4SdW9RxQA40bjlEFtPSqZ3HNXZ7yrUZXQWtrVkpia51nR088Jz0rMlmLgH+RPTDtj8CcI/E6QgsKXfrlxswbl3cT41qZVHi0+hNxE9vg+MSAVuYKgyWWFU7qlQCvmKmDPDjivBaFn7Aaz9qw71brpIeNXRwNiEbHy2+2+A0X8iIbc1Ca3RdVQ2rBLRXQDhNMi2syJkyty0ZTiLSNt+rhl4JgFZBz88q7b34MezNNNP7HX4oG+XpwjUe4KzDjk8EbBfxiPlLy7xkBioxRe+E="
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
