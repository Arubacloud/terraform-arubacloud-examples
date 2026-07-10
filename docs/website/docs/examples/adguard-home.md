---
title: AdGuard Home
---

# AdGuard Home on Aruba Cloud

Deploy [AdGuard Home](https://adguard.com/en/adguard-home/overview.html) — network-wide DNS ad-blocking and privacy protection — on Aruba Cloud using Terraform and cloud-init. AdGuard Home pairs naturally with the [WireGuard example](wireguard.md): point your VPN clients at the AdGuard Home DNS server for ad-free, tracker-free browsing everywhere your VPN is active.

> **Provider version:** arubacloud/arubacloud `~> 0.5` | **Terraform:** ≥ 1.9

---

## Introduction

AdGuard Home is a network-wide DNS filtering and ad-blocking solution. Like Pi-hole, it acts as a DNS sinkhole — but with a modern web UI, built-in DoH/DoT support, and per-client statistics. This example provisions a lightweight instance on Aruba Cloud with:

- AdGuard Home installed from the **official GitHub release binary** (no Docker needed)
- **DNS on port 53 (UDP + TCP)** — UDP for standard queries, TCP for large responses
- **Admin web UI on port 80** — access-restricted by `admin_cidr`
- `systemd-resolved` stub listener disabled so AdGuard Home can own port 53
- **Two default blocklists** — AdGuard DNS filter and AdAway

> **Best practice:** Deploy alongside the [WireGuard](wireguard.md) example. Set `dns_cidr` and `admin_cidr` to your WireGuard tunnel CIDR (e.g. `10.8.0.0/24`). Point VPN clients' DNS to the AdGuard Home Elastic IP.

---

## Architecture Overview

```mermaid
graph TB
    Client((VPN Client)) -->|DNS :53 UDP/TCP — dns_cidr| EIP[Elastic IP]
    Client -->|Admin :80 — admin_cidr| EIP
    Admin((Admin)) -->|SSH :22| EIP

    subgraph AC["Aruba Cloud — ITBG-Bergamo"]
        subgraph VPC["VPC / Subnet"]
            VM["CSO1A2 — 1 vCPU / 2 GB\nAdGuard Home\n20 GB disk"]
        end
        EIP --> VM
        SG["Security Group\nIN: 22 · 53 TCP · 53 UDP · 80\nOUT: all"]
    end

    VM -->|upstream DNS| Internet[(1.1.1.1 / 1.0.0.1)]
    SG -.-> VM
```

---

## Infrastructure Created

| Resource | Name pattern | Description |
|----------|-------------|-------------|
| `arubacloud_project` | `adguard-prod` | Project container |
| `arubacloud_vpc` | `adguard-prod-vpc` | Virtual Private Cloud |
| `arubacloud_subnet` | `adguard-prod-subnet` | Basic subnet |
| `arubacloud_securitygroup` | `adguard-prod-vm-sg` | Security group |
| `arubacloud_securityrule` | `adguard-prod-vm-ssh` | SSH ingress |
| `arubacloud_securityrule` | `adguard-prod-vm-admin-ui` | Admin UI ingress TCP 80 |
| `arubacloud_securityrule` | `adguard-prod-vm-dns-tcp` | DNS TCP 53 ingress |
| `arubacloud_securityrule` | `adguard-prod-vm-dns-udp` | DNS UDP 53 ingress |
| `arubacloud_elasticip` | `adguard-prod-vm-eip` | VM public IP |
| `arubacloud_blockstorage` | `adguard-prod-boot` | 20 GB boot disk (Performance) |
| `arubacloud_keypair` | `adguard-prod-keypair` | SSH public key |
| `arubacloud_cloudserver` | `adguard-prod-vm` | CloudServer VM |

---

## Estimated Monthly Cost

| Resource | Spec | Est. cost/mo |
|----------|------|-------------|
| CloudServer VM | CSO1A2 — 1 vCPU / 2 GB | ~€9 |
| Boot disk | 20 GB Performance | ~€3 |
| Elastic IP | — | ~€3 |
| **Total** | | **~€15/mo** |

---

## Requirements

- Terraform ≥ 1.9
- ArubaCloud Terraform Provider `~> 0.5`
- An ArubaCloud account with OAuth2 API credentials
- An SSH key pair

---

## Variables

### Required

| Variable | Description |
|----------|-------------|
| `arubacloud_client_id` | ArubaCloud OAuth2 client ID |
| `arubacloud_client_secret` | ArubaCloud OAuth2 client secret |
| `ssh_public_key` | SSH public key content |
| `adguard_password` | AdGuard Home admin password (min 8 chars) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `app_name` | `"adguard"` | Short name used in all resource names |
| `environment` | `"prod"` | Environment label |
| `location` | `"ITBG-Bergamo"` | ArubaCloud region |
| `zone` | `"ITBG-1"` | Availability zone |
| `billing_period` | `"Hour"` | `"Hour"` or `"Month"` |
| `vm_flavor` | `"CSO1A2"` | CloudServer flavor |
| `vm_image` | `"LU22-001"` | Boot disk image (Ubuntu 22.04 LTS) |
| `vm_disk_size_gb` | `20` | Boot disk size in GB |
| `ssh_cidr` | `"0.0.0.0/0"` | CIDR for SSH |
| `dns_cidr` | `"0.0.0.0/0"` | CIDR for DNS port 53 — **restrict to your VPN tunnel CIDR** |
| `admin_cidr` | `"0.0.0.0/0"` | CIDR for admin UI port 80 — **restrict to your VPN tunnel CIDR** |
| `upstream_dns_1` | `"1.1.1.1"` | Primary upstream resolver |
| `upstream_dns_2` | `"1.0.0.1"` | Secondary upstream resolver |
| `adguardhome_version` | `"0.107.52"` | AdGuard Home release version |

---

## Outputs

| Output | Description |
|--------|-------------|
| `admin_url` | AdGuard Home admin web interface URL |
| `dns_server` | IP to use as DNS server on VPN clients |
| `vm_public_ip` | Public IP address of the VM |
| `ssh_command` | SSH command to connect to the VM |

---

## Deployment Instructions

### 1. Clone and navigate

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples/adguard-home
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Set `adguard_password`. In production, also set:

```hcl
dns_cidr   = "10.8.0.0/24"   # your WireGuard tunnel CIDR
admin_cidr = "10.8.0.0/24"
ssh_cidr   = "203.0.113.42/32"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Bootstrap takes approximately **3–5 minutes** (binary download + bcrypt hash generation).

### 4. Point VPN clients at AdGuard Home

```bash
terraform output dns_server
```

Use the output IP as the DNS server in your WireGuard client config:

```ini
# In your WireGuard client [Peer] section:
DNS = <output of dns_server>
```

### 5. Access the admin UI

```bash
terraform output admin_url
```

Log in with username `admin` and your `adguard_password` to view query logs, manage blocklists, and configure filtering rules.

---

## Security Recommendations

1. **Always restrict `dns_cidr` and `admin_cidr`.** Leaving port 53 open to `0.0.0.0/0` makes your AdGuard Home an open DNS resolver — it will be abused for DNS amplification attacks. Set both CIDRs to your WireGuard tunnel CIDR.

2. **Do not expose the admin UI publicly.** Port 80 should only be reachable from VPN-connected clients.

3. **Use AdGuard Home with WireGuard.** The intended deployment model: WireGuard VPN provides secure tunnel access, and clients route DNS through AdGuard Home. See the [WireGuard example](wireguard.md).

---

## Upgrade Considerations

To upgrade AdGuard Home in-place, use the built-in updater from the admin UI (**Settings → Updates**), or via SSH:

```bash
ssh ubuntu@$(terraform output -raw vm_public_ip)
sudo systemctl stop AdGuardHome
sudo /opt/AdGuardHome/AdGuardHome --update
sudo systemctl start AdGuardHome
```

No VM replacement needed for AdGuard Home version upgrades.

---

## Troubleshooting

### AdGuard Home not responding to DNS queries

```bash
sudo systemctl status AdGuardHome
# Check port 53 is listening:
sudo ss -ulnp | grep :53
sudo ss -tlnp | grep :53
```

### Port 53 already in use after install

`systemd-resolved` stub listener was not disabled. Check:

```bash
sudo ss -ulnp sport = :53
cat /etc/systemd/resolved.conf | grep DNSStubListener
sudo systemctl restart systemd-resolved
sudo systemctl restart AdGuardHome
```

### Admin UI not loading

```bash
sudo systemctl status AdGuardHome
curl -sv http://localhost/
journalctl -u AdGuardHome -n 50
```

---

## References

- [AdGuard Home Documentation](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [AdGuard Home GitHub Releases](https://github.com/AdguardTeam/AdGuardHome/releases)
- [WireGuard Example](wireguard.md)
- [Pi-hole Example](pi-hole.md)
- [ArubaCloud Terraform Provider](https://registry.terraform.io/providers/arubacloud/arubacloud/latest/docs)

