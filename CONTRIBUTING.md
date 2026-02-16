# Contributing to JFrog Platform GitOps with Argo CD

Thank you for your interest in contributing! This project aims to provide production-ready GitOps configurations for deploying the JFrog Platform with Argo CD. We welcome contributions of all kinds.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Style Guide](#style-guide)
- [Reporting Issues](#reporting-issues)

## Ways to Contribute

- **New examples** — Add Argo CD Application manifests for new platforms, cloud providers, or use cases
- **Helm value overlays** — Contribute sizing profiles, security hardening configs, or cloud-specific values
- **Scripts** — Improve or add helper scripts for common operations
- **Documentation** — Fix typos, improve clarity, add diagrams, or write new guides
- **Bug reports** — Report issues with manifests, values, or scripts
- **Feature requests** — Suggest new examples or tooling improvements
- **Testing** — Validate configurations on different Kubernetes distributions and share results

## Getting Started

1. **Fork the repository** on GitHub.

2. **Clone your fork:**

   ```bash
   git clone https://github.com/<YOUR_USERNAME>/jfrog-gitops-test.git
   cd jfrog-gitops-test
   ```

3. **Create a branch:**

   ```bash
   git checkout -b feature/my-contribution
   ```

4. **Set up your environment:**

   - A Kubernetes cluster (minikube, kind, or a cloud provider)
   - Argo CD 2.6+ installed on the cluster
   - `kubectl` configured to target the cluster
   - `helm` 3.x (optional, for local chart inspection)

## Development Workflow

### Testing Your Changes

Before submitting a PR, validate your changes:

1. **YAML syntax** — Ensure all YAML files are valid:

   ```bash
   # Using yamllint (pip install yamllint)
   yamllint argocd-app.yaml customvalues.yaml

   # Or using kubectl dry-run
   kubectl apply --dry-run=client -f argocd-app.yaml
   ```

2. **Helm template rendering** — Verify values produce valid templates:

   ```bash
   helm repo add jfrog https://charts.jfrog.io
   helm template jfrog-platform jfrog/jfrog-platform \
     -f customvalues.yaml --debug
   ```

3. **Argo CD deployment** — Test in a non-production cluster:

   ```bash
   kubectl apply -f argocd-app.yaml
   kubectl get application jfrog-platform -n argocd -w
   ```

### Adding a New Example

If you're adding a new example configuration:

1. Create a directory under `examples/` with a descriptive name (e.g., `examples/aws-eks/`)
2. Include both `argocd-app.yaml` and `customvalues.yaml`
3. Add comments explaining platform-specific settings
4. Update the examples table in `README.md`
5. Test the configuration on the target platform

## Contribution Guidelines

### Do

- Keep manifests well-commented for newcomers
- Use placeholder values (e.g., `<DB_HOST>`, `<YOUR_ORG>`) instead of real credentials
- Pin chart versions in production examples
- Include `ignoreDifferences` for known drift sources
- Test on a real cluster before submitting

### Don't

- Commit secrets, credentials, certificates, or private keys
- Use `latest` as `targetRevision` in production examples
- Embed credentials inline — always reference Kubernetes secrets
- Break existing examples when adding new ones

## Pull Request Process

1. **Ensure your branch is up to date** with `main`:

   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Commit with clear messages:**

   ```
   Add EKS production example with IAM roles for service accounts

   - ArgoCD Application manifest with EKS-specific annotations
   - Values overlay with S3 filestore and RDS PostgreSQL
   - Helper script for IAM role creation
   ```

3. **Open a Pull Request** against `main` with:
   - A clear title describing the change
   - Description of what was changed and why
   - How you tested the changes
   - Any platform/version requirements

4. **Address review feedback** promptly.

5. **One approval** is required before merging.

## Style Guide

### YAML

- Use 2-space indentation
- Include comments for non-obvious configuration
- Use `---` document separator at the top of files
- Keep lines under 120 characters where practical

### Scripts

- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for safety
- Add usage information when run without arguments
- Use descriptive variable names in UPPER_CASE
- Quote all variable expansions

### Documentation

- Use Markdown for all docs
- Include code examples with language hints (e.g. triple backticks plus `yaml` or `bash`).
- Keep line length reasonable for readability
- Link to official docs rather than duplicating content

## Reporting Issues

When reporting an issue, please include:

1. **Environment details:**
   - Kubernetes distribution and version
   - Argo CD version
   - JFrog Platform chart version
   - Cloud provider (if applicable)

2. **Steps to reproduce** the issue

3. **Expected behavior** vs. **actual behavior**

4. **Relevant logs or screenshots:**

   ```bash
   # Argo CD Application status
   kubectl get application jfrog-platform -n argocd -o yaml

   # Pod status
   kubectl get pods -n jfrog-platform

   # Argo CD controller logs
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

## Questions?

- Open a [GitHub Discussion](https://github.com/nagarajuv-jfrog/jfrog-gitops-test/discussions)
- Visit [community.jfrog.com](https://community.jfrog.com/)

Thank you for helping make JFrog Platform GitOps better for everyone!
