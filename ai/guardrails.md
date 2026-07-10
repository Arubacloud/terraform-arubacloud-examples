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
| MD028 (blank in blockquote) | **enabled** | No bare blank lines between consecutive blockquote lines |
| MD033 (inline HTML) | disabled | |
| MD036 (emphasis as heading) | **enabled** | Bold/italic text on its own line is not a heading |
| MD040 (fenced code language) | **enabled** | Every fenced code block must declare a language |
| MD041 (first line h1) | disabled | |

**Common pitfall — MD022:** a heading immediately followed by content with no blank line in between:

```markdown
### Required
`var1`, `var2`   ← fails MD022

### Required

`var1`, `var2`   ← correct
```

**Common pitfall — MD036:** a bold or italic line used as a standalone paragraph heading:

```markdown
**Navigate to Settings**        ← fails MD036 (looks like a heading to the linter)

Go to **Settings** and click…   ← correct (bold mid-sentence is fine)

### Settings                    ← correct (use a real heading)
```

**Common pitfall — MD040:** a fenced code block with no language tag:

````markdown
```                 ← fails MD040
some code here
```

```bash            ← correct
some code here
```
````

Use `bash`, `hcl`, `yaml`, `text`, `caddyfile`, `nginx`, `ini`, `sql`, `python`, etc. When no syntax highlighting applies, use `text`.

**Common pitfall — MD028:** two separate `>` blockquotes with a bare blank line between them:

```markdown
> First note.

> Second note.    ← fails MD028 — bare blank line splits the blockquote

> First note.
>
> Second note.    ← correct — use `>` on the blank separator line
```

---

## 5. Docs build (Docusaurus sidebar vs. file consistency)

The documentation site uses Docusaurus (in `docs/website/`). Content is pre-processed from `docs/` at build time by `docs/website/scripts/preprocess-docs.js`.

Every entry in `docs/website/sidebars.js` must have a corresponding file in `docs/`. Missing files cause the Docusaurus build to fail.

**Before adding a new example to `sidebars.js`, the matching `docs/examples/<name>.md` stub must exist.** The stub uses an `include-markdown` directive:

```markdown
---
title: My Example
---

{%
  include-markdown "../../my-example/README.md"
%}
```

The preprocess script resolves this directive at build time, inlining the `README.md` content.

**Quick consistency check:**

```bash
# List sidebar entries
grep "examples/" docs/website/sidebars.js | sort

# List actual docs stubs
ls docs/examples/ | sort
```

The two lists must match. If a future example is referenced in the sidebar but not yet implemented, **remove it from `sidebars.js`** and add it back when the PR lands.

**Local docs development:**

```bash
cd docs/website
npm install
npm run start       # preprocesses docs then starts dev server
npm run build       # preprocesses docs then builds
```

---

## Adding a new example

1. Create the directory with the standard file set: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `cloud-init.yaml.tpl`, `terraform.tfvars.example`, `README.md`, `.gitignore`.
2. Add the example name to the matrix in `.github/workflows/terraform.yml` under the appropriate phase comment.
3. Create `docs/examples/<name>.md` with the `include-markdown` stub.
4. Add the example to the appropriate category in `docs/website/sidebars.js`.
5. Run all four checks above from the new example directory before opening the PR.
