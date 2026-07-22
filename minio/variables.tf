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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkHCyFqqdqzJw21x5i/MenBmYDhPQxXNrMjA0D98w3ZLlxbdrpoZ2NH8pupdVh5KM2vmDiOmsBKBVO2ivtkOXW+PrmrXi/g6KYw7uBZ82eCIi9rWclIJHpmM/kWeThjrGm9jlsz8Q5iq8TkPySuo7fo1ouIUVSBq9bexFl8+benOHopH39BqZ6WzrVVku+M6ZwDYR+88ffqEhWiVCZGhu3LLYWGXTaUsewOQOsbymx7R0jb/FboJ+rraMGRJYOlGAqgGt6VSeC9lOHSlgBuQVhrNxHI4HSxvCsqv7OtwIHbVs/VxEtWGwL6TO/iGzKX4hZ7G0+2BDiZ63IgTf+CEHbp9UaYU5xOC/f2iblgFLFwQnaTrrzDOuDWqcb/f8x56Ry7RV2bNvQ6XEPEB/x3+h09XU2CnyzdxQxDFclHxey+EIYqES4TQypqBc3W2FIKn8yDwyx45bg9rctvJ2PUA0gIlBzsPv29f3iGeIgXvwPlmHsT9ml8gToZ+HlvrhreAgWPMJA3c5goFxKIqp2LFNuejBQ+1Rdxx1J2rpAYEOtFbOixPPecsLz236YZRH4w+FdoGf9wPMcoaZOeqBN/sWmerWbPyaCLTUqRkNT0D0dmhkqG99PIkP7eJfJq/d+mdUNn4zTuQn3z5GKxgKrOszxNLHbRjfdFSOMaYkqWFga5Q=="
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
