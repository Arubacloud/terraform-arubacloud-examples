# Getting Started

## Prerequisites

| Tool | Minimum version | Install |
|------|-----------------|---------|
| Terraform | 1.9 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/downloads) |
| ArubaCloud Provider | 0.5 | Installed automatically by `terraform init` |
| Git | any | [git-scm.com](https://git-scm.com) |

You also need:

- An **Aruba Cloud account** with a project and API credentials (OAuth2 client ID and secret)
- An **SSH key pair** — the public key is uploaded to ArubaCloud; the private key stays on your machine
- Optional: a domain name for HTTPS (Let's Encrypt/Certbot) — some examples support automatic TLS

## 1. Clone the repository

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples
```

## 2. Choose an example

```bash
cd wordpress      # or: wireguard, nextcloud, minio, ...
```

## 3. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` in your editor and fill in at minimum:

```hcl
arubacloud_client_id     = "your-oauth2-client-id"
arubacloud_client_secret = "your-oauth2-client-secret"
ssh_public_key           = "ssh-rsa AAAA..."
```

All other variables have sensible defaults. See the example's `README.md` for a full variable reference.

## 4. Deploy

```bash
terraform init
terraform plan   # review changes before applying
terraform apply
```

Provisioning typically takes **5–15 minutes** — the VM boots, cloud-init installs packages, and the application starts.

## 5. Access the application

After `apply` completes, Terraform prints the outputs:

```bash
terraform output
```

Common outputs include `app_url`, `ssh_command`, and `admin_password`.

## 6. Destroy

```bash
terraform destroy
```

!!! warning "Elastic IP billing"
    Elastic IPs are billed even when not attached. `terraform destroy` releases them.
    Always destroy unused deployments to avoid unexpected charges.

## Credential security

- Never commit `terraform.tfvars` — it is gitignored by default
- Use `sensitive = true` variables (already set in all examples) to keep secrets out of plan output
- For production, store credentials in a secrets manager and reference them via environment variables or Vault
