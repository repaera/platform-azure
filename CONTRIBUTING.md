# Contributing to platform-azure

Thank you for your interest in contributing! This document provides guidelines for contributing to the `platform-azure` Terraform template.

## Repository

- **Repository:** https://github.com/repaera/platform-azure.git
- **Issues:** https://github.com/repaera/platform-azure/issues
- **Contact:** tech@repaera.com

## Code of Conduct

Be respectful, constructive, and inclusive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Open a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (Terraform version, Azure region, etc.)

### Suggesting Features

1. Open an issue describing the feature and its use case
2. Wait for maintainer feedback before implementing

### Pull Requests

1. **Fork** the repository
2. **Branch** from `main`: `git checkout -b feature/your-feature-name`
3. **Make changes** following existing code style
4. **Test** your changes: `terraform validate` in all environment directories
5. **Document** updates in README if user-facing
6. **Commit** with clear messages following conventional commits format
7. **Push** and open a Pull Request against `main`

## Development Setup

```bash
# Clone
git clone https://github.com/repaera/platform-azure.git
cd platform-azure

# Validate all environments
for env in single staging multiple; do
  cd environments/$env && terraform validate && cd ../..
done
```

## Code Style

- Terraform: follow existing block ordering (count/for_each first, then arguments, tags, depends_on, lifecycle)
- Variables: always include `description`, explicit `type`, and sensible defaults
- Outputs: always include `description`
- Scripts: use `set -euo pipefail` in bash scripts
- Documentation: update README for any user-facing changes

## Testing

Before submitting PR:
- [ ] `terraform validate` passes in `environments/single/`, `environments/staging/`, and `environments/multiple/`
- [ ] `terraform fmt -check` passes (no formatting issues)
- [ ] README reflects any changes
- [ ] Example manifests are syntactically valid YAML

## Security

- Never commit secrets, credentials, or `.terraform.tfvars` files
- Never commit SSH private keys or `kubeconfig` files
- Report security issues privately to tech@repaera.com

## Questions?

Contact: tech@repaera.com
