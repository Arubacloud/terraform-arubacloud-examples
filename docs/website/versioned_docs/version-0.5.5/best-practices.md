# Best Practices

## Terraform

**Pin the provider version** with a pessimistic constraint:

```hcl
arubacloud = {
  source  = "arubacloud/arubacloud"
  version = "~> 0.5"
}
```

**Never store secrets in state.** Mark all sensitive variables with `sensitive = true`. Use a remote backend (S3-compatible) for shared or production deployments.

**Use workspaces or separate state files** per environment:

```bash
terraform workspace new production
terraform workspace new staging
```

**Use `terraform plan` before every apply.** Review the diff, especially for resources that require replacement (marked `# forces replacement`).

## cloud-init

**Separate configuration from commands.** Use `write_files` to drop configuration files and `runcmd` for shell commands. This is more readable and easier to debug than embedding heredocs in shell scripts.

**Wait for async resources.** Managed DBaaS instances may not be fully ready when the VM first boots. Always use a TCP readiness check before attempting a database connection:

```bash
until (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null; do sleep 10; done
```

**Log all progress.** Add `echo` statements and a `final_message` so you can tail `/var/log/cloud-init-output.log` to follow the bootstrap.

**Test cloud-init locally** with `cloud-init devel schema --config-file cloud-init.yaml.tpl` (requires the cloud-init package).

## Security

See [Security Recommendations](security.md) for a dedicated guide.

## Cost management

- Set `billing_period = "Hour"` during development; switch to `"Month"` for production to reduce per-unit cost.
- Always run `terraform destroy` when finished with a test deployment — Elastic IPs are billed even when idle.
- Right-size VMs: start small and scale up. You can resize a CloudServer without destroying it.

## Naming

Use short but unique prefixes. ArubaCloud resource display names have length limits. Keep the `name_prefix` under 15 characters to avoid API errors when combined with resource suffixes like `-vm-eip`.
