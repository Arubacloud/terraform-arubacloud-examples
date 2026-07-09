variable "name_prefix" {
  description = "Short prefix applied to every resource name (e.g. 'wp-prod'). Max 15 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,13}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 2–15 lowercase alphanumeric characters or hyphens, and must start and end with an alphanumeric character."
  }
}

variable "location" {
  description = "ArubaCloud region identifier (e.g. 'ITBG-Bergamo')."
  type        = string
  default     = "ITBG-Bergamo"
}

variable "project_id" {
  description = "ID of the ArubaCloud project that will own all resources."
  type        = string
}

variable "tags" {
  description = "List of tags to attach to all resources created by this module."
  type        = list(string)
  default     = []
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

variable "vm_ingress_ports" {
  description = <<-EOT
    Map of TCP ingress rules for the VM security group.
    Key   = short name used in the rule resource name (e.g. 'ssh', 'http', 'https').
    Value = object with:
      port — TCP port as a string (e.g. "22", "80", "443").
      cidr — Source CIDR (e.g. "0.0.0.0/0" or "203.0.113.0/24").
  EOT
  type = map(object({
    port = string
    cidr = string
  }))
  default = {
    ssh   = { port = "22",  cidr = "0.0.0.0/0" }
    http  = { port = "80",  cidr = "0.0.0.0/0" }
    https = { port = "443", cidr = "0.0.0.0/0" }
  }
}

variable "create_dbaas_network" {
  description = "When true, creates a dedicated security group and Elastic IP for a DBaaS instance."
  type        = bool
  default     = false
}
