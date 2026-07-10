## Description

<!-- Brief description of the change. For new examples, name the application. -->

## Type of change

- [ ] New example
- [ ] Bug fix in existing example
- [ ] Documentation update
- [ ] Infrastructure / CI change

## Checklist — New Example

<!-- Fill in the example name and tick each item. Delete this section for non-example PRs. -->

**Example:** `<name>`

- [ ] `versions.tf` — provider constraints `~> 0.5`; `required_version = ">= 1.9"`
- [ ] `variables.tf` — every variable has `description` and `type`; sensitive inputs have `sensitive = true`; validation blocks where useful
- [ ] `main.tf` — uses `modules/network`; no inline VPC/subnet/SG duplication
- [ ] `outputs.tf` — URL, VM public IP, SSH command; every output has `description`
- [ ] `cloud-init.yaml.tpl` — idempotent bootstrap; passwords passed via base64-encoded `write_files`, decoded in `runcmd`, files deleted after use
- [ ] `terraform.tfvars.example` — all required vars with placeholder values
- [ ] `README.md` — includes Mermaid architecture diagram, variables tables, estimated cost, deployment instructions
- [ ] `.gitignore` — ignores `cloud-init.yaml` and `terraform.tfvars`
- [ ] `docs/examples/<name>.md` — `include-markdown` stub created
- [ ] Added to `matrix.example` in `.github/workflows/terraform.yml`
- [ ] Added to appropriate section in `mkdocs.yml` nav

## Pre-submit Checks

- [ ] `terraform fmt -check -recursive -diff` passes
- [ ] `terraform init -backend=false && terraform validate` passes (run from example dir)
- [ ] `tflint --recursive --format compact` passes
- [ ] `npx markdownlint-cli2 "**/*.md"` passes
- [ ] mkdocs nav entries match files in `docs/examples/`
