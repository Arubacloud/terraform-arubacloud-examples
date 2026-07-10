# Contributing

Thank you for contributing to terraform-arubacloud-examples! See the full [Contributing Guide](docs/contributing.md) for detailed instructions.

## Quick Summary

1. Open an issue or pick an existing one to discuss the example.
2. Fork the repository and create a branch: `feat/<app-name>`.
3. Create the example directory with the [required files](docs/contributing.md#adding-a-new-example).
4. Run the pre-submit checks (see [guardrails](ai/guardrails.md) for full details):
   - `terraform fmt -check -recursive -diff`
   - `cd <example> && terraform init -backend=false && terraform validate`
   - `tflint --recursive --format compact`
   - `npx markdownlint-cli2 "**/*.md"`
5. Add the example to the CI matrix and `mkdocs.yml` nav.
6. Open a PR — the PR template guides you through the checklist.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please be respectful and inclusive.
