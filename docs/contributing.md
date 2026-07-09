# Contributing

Contributions to terraform-arubacloud-examples are welcome. This document explains how to add a new example, fix an existing one, or improve documentation.

## Before you start

- Open an issue to discuss the example you want to add (unless it is already on the roadmap).
- Check that the application is not already being worked on by someone else.

## Adding a new example

### 1. Create the directory

```bash
mkdir myapp
```

### 2. Create required files

Every example must contain exactly these files:

```text
myapp/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── cloud-init.yaml.tpl
├── terraform.tfvars.example
├── .gitignore
└── LICENSE
```

Copy `wordpress/` as a template and adapt it.

### 3. Use the shared network module

```hcl
module "network" {
  source = "../modules/network"
  # ...
}
```

Do not duplicate VPC / subnet / security group / Elastic IP code inline.

### 4. Write a complete README

Follow the WordPress README as the template. Every README must include:

- Architecture Mermaid diagram
- Infrastructure created (bullet list)
- VM sizing recommendation
- Estimated monthly cost
- All variables (required and optional)
- Deployment and destroy instructions
- Security recommendations
- Troubleshooting section

### 5. Add a docs page

Create `docs/examples/myapp.md`:

```markdown
---
title: My App
---

{%
  include-markdown "../../myapp/README.md"
%}
```

Add it to the `nav:` section in `mkdocs.yml`.

### 6. Add to CI matrix

Add the example to the `matrix.example` list in `.github/workflows/terraform.yml`.

## Code style

- Run `terraform fmt -recursive` before committing.
- Keep resource names short (≤ 15 chars prefix) to avoid ArubaCloud name-length errors.
- Mark all secrets as `sensitive = true`.
- Add `validation {}` blocks for variables that have meaningful constraints.
- Do not hardcode location, zone, or flavor names — always use variables with documented defaults.

## Pull request checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes for the new example
- [ ] README follows the template structure
- [ ] `docs/examples/myapp.md` created and added to `mkdocs.yml`
- [ ] Example added to CI matrix
- [ ] `terraform.tfvars.example` contains all required variables with placeholder values

## Running the docs locally

```bash
cd terraform-arubacloud-examples
pip install -r docs/requirements.txt
mkdocs serve
# Open http://127.0.0.1:8000
```
