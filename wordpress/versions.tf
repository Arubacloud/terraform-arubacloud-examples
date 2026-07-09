terraform {
  required_version = ">= 1.9"

  required_providers {
    arubacloud = {
      source  = "arubacloud/arubacloud"
      version = "~> 0.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "arubacloud" {
  client_id     = var.arubacloud_client_id
  client_secret = var.arubacloud_client_secret

  resource_timeout = "30m"
}
