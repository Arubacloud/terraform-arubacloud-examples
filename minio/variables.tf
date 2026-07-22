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
  default = "minio"
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
  default     = "CSO2A4"
  description = "CloudServer flavor."
}

variable "vm_image" {
  type        = string
  default     = "LU22-001"
  description = "Boot image."
}

variable "vm_disk_size_gb" {
  type    = number
  default = 100
  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "Minimum 20 GB."
  }
  description = "Boot disk size. Use a large value — this is where MinIO stores all objects."
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for SSH."
}

variable "api_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for MinIO S3 API (port 9000)."
}

variable "console_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for MinIO Console (port 9001). Restrict to your IP."
}

variable "minio_root_user" {
  type        = string
  default     = "minioadmin"
  description = "MinIO root access key (username)."
}

variable "minio_root_password" {
  type        = string
  sensitive   = true
  description = "MinIO root secret key. Minimum 8 characters."
  default     = "K7m@P4z!L9"

  validation {
    condition     = length(var.minio_root_password) >= 8
    error_message = "minio_root_password must be at least 8 characters."
  }
}

variable "minio_data_dir" {
  type        = string
  default     = "/data/minio"
  description = "Path on the VM where MinIO stores objects."
}
