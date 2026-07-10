# Security Recommendations

## Network security

**Restrict SSH access to your IP.** Every example exposes an `ssh_cidr` variable. Set it to your public IP:

```hcl
ssh_cidr = "203.0.113.42/32"   # your IP only
```

The default `0.0.0.0/0` is intentional for getting-started convenience. Change it before deploying to production.

**Expose only required ports.** Each example's security group opens only the ports the application needs. Do not add rules for ports you are not using.

**Restrict DBaaS access to the VM's IP.** The MySQL security rule in database-backed examples allows ingress only from the VM's Elastic IP, not from the public internet.

## Credentials

**Use strong, unique passwords.** Every example validates that passwords meet minimum length. Use a password manager to generate credentials.

**Rotate credentials periodically.** Update `db_password` and application admin passwords on a schedule. For most examples, a `terraform apply` with a new password will update the DBaaS user and trigger a VM replacement (new cloud-init user_data) to update the application config.

**Do not commit `terraform.tfvars`.** It is gitignored by default in every example. Store it in a secrets manager or CI/CD environment variables.

## Application hardening

**Enable HTTPS.** All examples that expose a web UI include optional Certbot/Let's Encrypt support. Set the `domain` variable to enable it. Do not run production applications over plain HTTP.

**Keep software up to date.** cloud-init runs `package_upgrade: true` on first boot. Set up unattended-upgrades for ongoing patching:

```yaml
packages:
  - unattended-upgrades
runcmd:
  - dpkg-reconfigure -f noninteractive unattended-upgrades
```

**Review WordPress/application-specific hardening** in each example's README Security section.

## Provider credentials

Store API credentials as environment variables rather than in `terraform.tfvars`:

```bash
export TF_VAR_arubacloud_client_id="your-client-id"
export TF_VAR_arubacloud_client_secret="your-client-secret"
```

Or use a CI/CD secrets store (GitHub Actions secrets, GitLab CI variables, etc.).
