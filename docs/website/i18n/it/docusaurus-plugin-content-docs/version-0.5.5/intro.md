# ArubaCloud Terraform Examples

> Stack Terraform pronti per la produzione per distribuire applicazioni open source popolari su **Aruba Cloud**.

## Cos'è questo?

Questo repository è la raccolta ufficiale di esempi Terraform della community per il [Provider Terraform Aruba Cloud](https://registry.terraform.io/providers/arubacloud/arubacloud/latest). Ogni esempio distribuisce uno stack applicativo completo e autonomo usando:

- **Cloud Server** (macchine virtuali) provisionate con **cloud-init**
- **Managed MySQL DBaaS** dove applicabile
- **Elastic IP**, **VPC**, **subnet** e **security group** per il networking
- **Block Storage** per i dati persistenti

Tutti gli esempi seguono la stessa struttura, usano lo stesso modulo di rete condiviso e sono documentati a standard di produzione.

## Quick Start

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples/wordpress
cp terraform.tfvars.example terraform.tfvars
# Modifica terraform.tfvars con le tue credenziali e impostazioni
terraform init
terraform apply
```

## Esempi in Breve

| Esempio | Caso d'uso | Dimensione VM | DBaaS | Costo stimato/mese |
|---------|-----------|---------------|-------|-------------------|
| [WordPress](examples/wordpress.md) | CMS / Blog | 4 vCPU / 8 GB | MySQL 8.0 | ~€90 |
| [WireGuard](examples/wireguard.md) | Server VPN | 1 vCPU / 2 GB | — | ~€15 |
| [Docker Host](examples/docker-host.md) | Runtime container | 2 vCPU / 4 GB | — | ~€30 |
| [Uptime Kuma](examples/uptime-kuma.md) | Monitoraggio / pagina di stato | 1 vCPU / 2 GB | — | ~€12 |
| [Vaultwarden](examples/vaultwarden.md) | Gestore password | 1 vCPU / 2 GB | — | ~€12 |
| [MinIO](examples/minio.md) | Object storage (S3-compat) | 2 vCPU / 4 GB | — | ~€45 |
| [Traefik](examples/traefik.md) | Reverse proxy + auto-TLS | 1 vCPU / 2 GB | — | ~€15 |
| [Nextcloud](examples/nextcloud.md) | Sync file / cloud storage | 4 vCPU / 8 GB | MySQL 8.0 | ~€110 |

Altri esempi sono elencati nella barra laterale di navigazione.

## Prerequisiti

- Terraform ≥ 1.9
- ArubaCloud Terraform Provider ≥ 0.5
- Un account Aruba Cloud con credenziali API (OAuth2 client ID + secret)
- Una coppia di chiavi SSH

Consulta la [Guida Rapida](getting-started.md) per una procedura dettagliata.
