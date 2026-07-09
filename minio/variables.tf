variable "arubacloud_client_id"     { type = string; sensitive = true; description = "ArubaCloud OAuth2 client ID." }
variable "arubacloud_client_secret"  { type = string; sensitive = true; description = "ArubaCloud OAuth2 client secret." }
variable "ssh_public_key"            { type = string; description = "SSH public key content." }

variable "app_name" {
  type    = string
  default = "minio"
  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.app_name))
    error_message = "app_name must be 2–10 lowercase alphanumeric characters or hyphens."
  }
  description = "Short name used in resource names."
}

variable "environment"    { type = string; default = "prod";         description = "Environment label." }
variable "location"       { type = string; default = "ITBG-Bergamo"; description = "ArubaCloud region." }
variable "zone"           { type = string; default = "ITBG-1";       description = "Availability zone." }
variable "billing_period" { type = string; default = "Hour";         description = "'Hour' or 'Month'." }
variable "vm_flavor"      { type = string; default = "CSO2A4";       description = "CloudServer flavor." }
variable "vm_image"       { type = string; default = "LU22-001";     description = "Boot image." }
variable "vm_disk_size_gb" {
  type    = number
  default = 100
  validation { condition = var.vm_disk_size_gb >= 20; error_message = "Minimum 20 GB." }
  description = "Boot disk size. Use a large value — this is where MinIO stores all objects."
}

variable "ssh_cidr"    { type = string; default = "0.0.0.0/0"; description = "CIDR for SSH." }
variable "api_cidr"    { type = string; default = "0.0.0.0/0"; description = "CIDR for MinIO S3 API (port 9000)." }
variable "console_cidr"{ type = string; default = "0.0.0.0/0"; description = "CIDR for MinIO Console (port 9001). Restrict to your IP." }

variable "minio_root_user" {
  type        = string
  default     = "minioadmin"
  description = "MinIO root access key (username)."
}

variable "minio_root_password" {
  type        = string
  sensitive   = true
  description = "MinIO root secret key. Minimum 8 characters."

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
