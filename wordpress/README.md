# WordPress on Aruba Cloud

Deploy a production-ready [WordPress](https://wordpress.org) site on Aruba Cloud using Terraform and cloud-init. No manual server configuration required.

> **Provider version:** arubacloud/arubacloud `~> 0.5` | **Terraform:** ≥ 1.9

---

## Introduction

WordPress is the world's most popular content management system, powering over 40% of all websites. This example provisions a complete WordPress stack on Aruba Cloud with:

- A **CloudServer VM** running Apache 2.4 and PHP 8.x, fully bootstrapped by cloud-init
- A **Managed MySQL 8.0 DBaaS** instance — no self-managed database server
- A dedicated **VPC, subnet, and security groups** via the shared network module
- **Elastic IPs** for the VM and DBaaS
- Optional **Let's Encrypt HTTPS** when a custom domain is provided

---

## Architecture Overview

The VM hosts WordPress behind Apache. The database runs on a separate managed DBaaS instance in the same VPC. The MySQL security group allows inbound connections only from the VM's Elastic IP.

```mermaid
graph TB
    User((Internet)) -->|HTTP :80 / HTTPS :443| EIP_VM[Elastic IP — VM]
    Admin((Admin)) -->|SSH :22 restricted CIDR| EIP_VM

    subgraph AC["Aruba Cloud — ITBG-Bergamo"]
        subgraph VPC["VPC / Subnet"]
            VM["CloudServer VM\nApache 2.4 + PHP 8.x\nWordPress 6.x"]
            DB[("Managed MySQL 8.0\nDBaaS")]
        end
        EIP_VM --> VM
        EIP_DB[Elastic IP — DBaaS] --> DB
        SG_VM["VM Security Group\nIN: 22 · 80 · 443\nOUT: all"]
        SG_DB["DBaaS Security Group\nIN: 3306 from VM IP\nOUT: all"]
    end

    VM -->|MySQL :3306| DB
    SG_VM -.-> VM
    SG_DB -.-> DB
```

---

## Infrastructure Created

| Resource | Name pattern | Description |
|----------|-------------|-------------|
| `arubacloud_project` | `wp-prod` | Project container |
| `arubacloud_vpc` | `wp-prod-vpc` | Virtual Private Cloud |
| `arubacloud_subnet` | `wp-prod-subnet` | Basic subnet |
| `arubacloud_securitygroup` | `wp-prod-vm-sg` | VM security group |
| `arubacloud_securitygroup` | `wp-prod-db-sg` | DBaaS security group |
| `arubacloud_securityrule` | `wp-prod-vm-ssh` | SSH ingress (restricted CIDR) |
| `arubacloud_securityrule` | `wp-prod-vm-http` | HTTP ingress (0.0.0.0/0) |
| `arubacloud_securityrule` | `wp-prod-vm-https` | HTTPS ingress (0.0.0.0/0) |
| `arubacloud_securityrule` | `wp-prod-db-mysql` | MySQL ingress from VM IP only |
| `arubacloud_elasticip` | `wp-prod-vm-eip` | VM public IP |
| `arubacloud_elasticip` | `wp-prod-db-eip` | DBaaS public IP |
| `arubacloud_blockstorage` | `wp-prod-boot` | 40 GB boot disk (Performance) |
| `arubacloud_keypair` | `wp-prod-keypair` | SSH public key |
| `arubacloud_dbaas` | `wp-prod-dbaas` | Managed MySQL 8.0 |
| `arubacloud_database` | `wordpress` | WordPress logical database |
| `arubacloud_dbaasuser` | `wordpress` | MySQL application user |
| `arubacloud_databasegrant` | — | liteadmin grant |
| `arubacloud_cloudserver` | `wp-prod-vm` | CloudServer VM |

---

## VM Sizing Recommendation

| Workload | vCPU | RAM | Disk | Flavor |
|----------|------|-----|------|--------|
| Development / test | 2 | 4 GB | 20 GB | `CSO2A4` |
| Small site (< 5k visits/day) | 4 | 8 GB | 40 GB | `CSO4A8` *(default)* |
| Medium site (< 50k visits/day) | 8 | 16 GB | 80 GB | `CSO8A16` |
| High-traffic | — | — | — | Add a caching layer (Redis, Varnish) before scaling |

For the DBaaS: `DBO2A8` (2 vCPU / 8 GB) covers most WordPress sites. Add read replicas for high-read workloads.

---

## Estimated Monthly Cost

> Approximate prices for ITBG-Bergamo, hourly billing. Actual prices may vary — verify in the [ArubaCloud console](https://www.cloud.it).

| Resource | Spec | Est. cost/mo |
|----------|------|-------------|
| CloudServer VM | CSO4A8 — 4 vCPU / 8 GB | ~€35 |
| Boot disk | 40 GB Performance | ~€5 |
| Managed MySQL | DBO2A8 — 2 vCPU / 8 GB | ~€40 |
| DBaaS storage | 20 GB | ~€3 |
| Elastic IP × 2 | — | ~€10 |
| **Total** | | **~€93/mo** |

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
| `ssh_public_key` | SSH public key content (e.g. contents of `~/.ssh/id_ed25519.pub`) |
| `db_password` | MySQL password for the WordPress user (min 16 chars, no newlines) |
| `wp_admin_password` | WordPress admin password (min 16 chars, no newlines) |
| `wp_admin_email` | WordPress admin email (also used for Let's Encrypt registration) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `app_name` | `"wp"` | Short name used in all resource names |
| `environment` | `"prod"` | Environment label (`prod`, `staging`, `dev`) |
| `location` | `"ITBG-Bergamo"` | ArubaCloud region |
| `zone` | `"ITBG-1"` | Availability zone |
| `billing_period` | `"Hour"` | `"Hour"` or `"Month"` |
| `vm_flavor` | `"CSO4A8"` | CloudServer flavor |
| `vm_image` | `"LU22-001"` | Boot disk image (Ubuntu 22.04 LTS) |
| `vm_disk_size_gb` | `40` | Boot disk size in GB |
| `ssh_cidr` | `"0.0.0.0/0"` | CIDR for SSH access — **restrict to your IP in production** |
| `dbaas_flavor` | `"DBO2A8"` | DBaaS flavor |
| `db_storage_gb` | `20` | DBaaS initial storage in GB |
| `wp_admin_user` | `"admin"` | WordPress admin username |
| `wp_title` | `"My WordPress Site"` | Site title |
| `domain` | `""` | Custom domain for HTTPS — leave empty to use the Elastic IP |

---

## Deployment Instructions

### 1. Clone and navigate

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples/wordpress
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your credentials and passwords.

> **Tip:** Store credentials as environment variables to avoid writing them to disk:

```bash
export TF_VAR_arubacloud_client_id="your-id"
export TF_VAR_arubacloud_client_secret="your-secret"
```

### 3. Initialize and deploy

```bash
terraform init
terraform plan   # review the execution plan
terraform apply
```

### 4. Access WordPress

After apply completes (typically 10–15 minutes):

```bash
terraform output site_url          # e.g. http://203.0.113.10
terraform output wp_admin_url      # e.g. http://203.0.113.10/wp-admin
terraform output -raw wp_admin_password
```

Open the admin URL in your browser and log in.

### 5. Follow cloud-init progress (optional)

While cloud-init runs, you can tail the bootstrap log:

```bash
ssh ubuntu@$(terraform output -raw vm_public_ip)
sudo tail -f /var/log/cloud-init-output.log
```

---

## Destroy Instructions

```bash
terraform destroy
```

This removes all created resources. The DBaaS data **is destroyed** — take a snapshot first if you need to preserve data:

```bash
# Take a DBaaS backup before destroying (manual step via console or API)
terraform destroy
```

---

## Security Recommendations

1. **Restrict SSH to your IP.** Set `ssh_cidr = "your.ip.address/32"` in `terraform.tfvars`. The default `0.0.0.0/0` is for getting-started convenience only.

2. **Use a custom domain with HTTPS.** Set the `domain` variable. Certbot will automatically provision and renew a Let's Encrypt certificate. WordPress stores the site URL in the database — changing from HTTP to HTTPS after deployment requires a database URL update.

3. **Change the default admin username.** Set `wp_admin_user` to something other than `"admin"` to reduce brute-force exposure.

4. **Keep WordPress and plugins updated.** Enable automatic updates via the WordPress dashboard or `wp-cron`.

5. **Install a security plugin.** Consider Wordfence or iThemes Security after deployment.

6. **Do not expose MySQL publicly.** The DBaaS security group already restricts MySQL to the VM's IP. Do not add `0.0.0.0/0` ingress rules to the DBaaS security group.

---

## Upgrade Considerations

### WordPress core / plugin updates

Update through the WordPress admin dashboard or via WP-CLI:

```bash
ssh ubuntu@$(terraform output -raw vm_public_ip)
sudo -u www-data wp --path=/var/www/html core update
sudo -u www-data wp --path=/var/www/html plugin update --all
```

### PHP version upgrade

Change the PHP packages in `cloud-init.yaml.tpl` and trigger a VM replacement by modifying `user_data` (e.g. add a timestamp comment). Run `terraform apply` to replace the instance with a fresh bootstrap.

### Provider upgrade

When the provider releases a new minor version, update the constraint in `versions.tf` and run `terraform init -upgrade`. Always review the provider CHANGELOG before upgrading.

---

## Screenshots

> **Screenshot placeholder.** After deployment, add screenshots of the WordPress front page and admin dashboard here.

| Admin dashboard | Front page |
|-----------------|------------|
| *(screenshot)* | *(screenshot)* |

---

## Login Credentials After Deployment

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| WordPress Admin | `$(terraform output wp_admin_url)` | `$(terraform output wp_admin_user)` | `$(terraform output -raw wp_admin_password)` |
| MySQL | `$(terraform output dbaas_host):3306` | `wordpress` | `$(terraform output -raw db_password)` |
| SSH | `$(terraform output ssh_command)` | `ubuntu` | SSH key |

---

## Troubleshooting

### "Error establishing a database connection"

1. **DBaaS not ready yet.** cloud-init waits up to 15 minutes for MySQL. If the VM booted before the DBaaS was ready, SSH in and check `/var/log/cloud-init-output.log`.
2. **Missing database grant.** Verify that `arubacloud_databasegrant.wordpress` was created successfully (`terraform state show arubacloud_databasegrant.wordpress`).
3. **Firewall.** Confirm the DBaaS security group has a MySQL ingress rule (`arubacloud_securityrule.dbaas_mysql`) with the correct source IP.

### Apache serves "It works!" instead of WordPress

The cloud-init script removes `/var/www/html/index.html` after deploying WordPress. If you applied an older version, SSH in and run:

```bash
sudo rm -f /var/www/html/index.html
```

### Certbot fails to issue a certificate

- DNS must resolve the domain to the VM's Elastic IP **before** `terraform apply`.
- Certbot requires ports 80 and 443 to be reachable. Verify your security group rules.
- Check `/var/log/letsencrypt/letsencrypt.log` for details.

### cloud-init bootstrap did not complete

```bash
ssh ubuntu@$(terraform output -raw vm_public_ip)
sudo systemctl status cloud-init
sudo cat /var/log/cloud-init-output.log
```

Look for the `final_message` near the end of the log. If missing, scroll up to find the error.

### Plan errors: "resource name already exists"

A previous `terraform destroy` may not have completed. Either finish destroying or change `app_name` / `environment` to use a different resource name prefix.

---

## References

- [WordPress Documentation](https://wordpress.org/documentation/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
- [ArubaCloud Terraform Provider](https://registry.terraform.io/providers/arubacloud/arubacloud/latest/docs)
- [ArubaCloud API Documentation](https://api.arubacloud.com/docs/)
- [cloud-init Reference](https://cloudinit.readthedocs.io/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
