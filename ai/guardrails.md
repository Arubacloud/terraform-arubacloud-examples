# Guardrails — Pre-submit Checklist

Run these checks locally before opening or pushing to a PR. They mirror the CI jobs in `.github/workflows/terraform.yml` exactly.

---

## 1. HCL format

```bash
terraform fmt -check -recursive -diff
```

Auto-fix: `terraform fmt -recursive`

**Common pitfall:** never use semicolons to pack multiple arguments onto one line inside a block body. HCL does not treat `;` as a statement separator — arguments after the first will be silently dropped or cause a parse error.

```hcl
# WRONG — error_message is dropped by the parser
validation { condition = var.x >= 0; error_message = "Must be non-negative." }

# CORRECT
validation {
  condition     = var.x >= 0
  error_message = "Must be non-negative."
}
```

---

## 2. Terraform init + validate (per example)

Run from each example directory that was added or modified:

```bash
cd <example>
terraform init -backend=false
terraform validate
```

**Common pitfalls:**

- `templatefile()` — every variable referenced inside the `.tpl` file must appear in the vars map. The error surfaces at `terraform validate` time:

  ```text
  Invalid value for "vars" parameter: vars map does not contain key "foo"
  ```

- Variable `validation` blocks must use multi-line format (see §1 above).

---

## 3. TFLint

```bash
tflint --init
tflint --recursive --format compact
```

The active ruleset is `plugin "terraform" { enabled = true; preset = "recommended" }` (`.tflint.hcl`). Key rules that bite:

| Rule | What it checks |
|------|---------------|
| `terraform_documented_variables` | Every `variable` block must have a `description` |
| `terraform_documented_outputs` | Every `output` block must have a `description` |
| `terraform_typed_variables` | Every `variable` block must have a `type` |
| `terraform_required_version` | `versions.tf` must declare `required_version` |
| `terraform_required_providers` | `versions.tf` must declare `required_providers` |

---

## 4. Markdown lint

```bash
npx markdownlint-cli2 "**/*.md"
```

Config is in `.markdownlint.json`. Rules in effect (all others default to enabled):

| Rule | Status | Note |
|------|--------|------|
| MD013 (line length) | disabled | Long lines are fine |
| MD022 (blanks around headings) | **enabled** | Must have a blank line above AND below every heading |
| MD024 (duplicate headings) | siblings only | Duplicates allowed if not siblings |
| MD033 (inline HTML) | disabled | |
| MD041 (first line h1) | disabled | |

**Common pitfall — MD022:** a heading immediately followed by content with no blank line in between:

```markdown
### Required
`var1`, `var2`   ← fails MD022

### Required

`var1`, `var2`   ← correct
```

---

## 5. Docs build (mkdocs nav vs. file consistency)

Every entry in the `nav:` section of `mkdocs.yml` must have a corresponding file in `docs/`. Missing files cause `mkdocs gh-deploy` to fail silently with exit code 1 — the CI "Deploy to GitHub Pages" job will be red.

**Before adding a new example to mkdocs.yml nav, the matching `docs/examples/<name>.md` stub must exist.** The stub is a one-liner:

```markdown
---
title: My Example
---

{%
  include-markdown "../../my-example/README.md"
%}
```

**Quick consistency check:**

```bash
# List nav entries (rough grep)
grep 'examples/' mkdocs.yml | sed "s|.*examples/||;s|'||g" | sort

# List actual docs files
ls docs/examples/ | sort
```

The two lists must match. If a future example is referenced in nav but not yet implemented, **remove it from `mkdocs.yml`** and add it back when the PR lands.

---

## Adding a new example

1. Create the directory with the standard file set: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `cloud-init.yaml.tpl`, `terraform.tfvars.example`, `README.md`, `.gitignore`.
2. Add the example name to the matrix in `.github/workflows/terraform.yml` under the appropriate phase comment.
3. Create `docs/examples/<name>.md` with the `include-markdown` stub.
4. Add the example to the appropriate section of `mkdocs.yml` nav.
5. Run all four checks above from the new example directory before opening the PR.
