# ArubaCloud Terraform Examples

> Production-ready Terraform stacks for deploying popular open-source applications on **Aruba Cloud**.

## What is this?

This repository is the official collection of community Terraform examples for the [Aruba Cloud Terraform Provider](https://registry.terraform.io/providers/arubacloud/arubacloud/latest). Each example deploys a complete, self-contained application stack using:

- **Cloud Servers** (virtual machines) provisioned with **cloud-init**
- **Managed MySQL DBaaS** where applicable
- **Elastic IPs**, **VPCs**, **subnets**, and **security groups** for networking
- **Block Storage** for persistent data

All examples follow the same structure, use the same shared network module, and are documented to production standards.

## Quick Start

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples/wordpress
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials and settings
terraform init
terraform apply
```

## Examples at a Glance

| Example | Use case | VM size | DBaaS | Est. cost/mo |
|---------|----------|---------|-------|-------------|
| [WordPress](examples/wordpress.md) | CMS / Blog | 4 vCPU / 8 GB | MySQL 8.0 | ~€90 |
| [WireGuard](examples/wireguard.md) | VPN server | 1 vCPU / 2 GB | — | ~€15 |
| [Docker Host](examples/docker-host.md) | Container runtime | 2 vCPU / 4 GB | — | ~€30 |
| [Uptime Kuma](examples/uptime-kuma.md) | Monitoring / status page | 1 vCPU / 2 GB | — | ~€12 |
| [Vaultwarden](examples/vaultwarden.md) | Password manager | 1 vCPU / 2 GB | — | ~€12 |
| [MinIO](examples/minio.md) | Object storage (S3-compat) | 2 vCPU / 4 GB | — | ~€45 |
| [Traefik](examples/traefik.md) | Reverse proxy + auto-TLS | 1 vCPU / 2 GB | — | ~€15 |
| [Nextcloud](examples/nextcloud.md) | File sync / cloud storage | 4 vCPU / 8 GB | MySQL 8.0 | ~€110 |

More examples are listed in the navigation sidebar.

## Prerequisites

- Terraform ≥ 1.9
- ArubaCloud Terraform Provider ≥ 0.5
- An Aruba Cloud account with API credentials (OAuth2 client ID + secret)
- An SSH key pair

See [Getting Started](getting-started.md) for a detailed walkthrough.
