terraform {
  required_version = ">= 1.9"

  required_providers {
    arubacloud = {
      source  = "arubacloud/arubacloud"
      version = "~> 1.0"
    }
  }
}
