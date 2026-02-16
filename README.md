# JFrog Platform GitOps with Argo CD

Deploy and manage the [JFrog Platform](https://jfrog.com/platform/) on Kubernetes using [Argo CD](https://argo-cd.readthedocs.io/) and GitOps principles.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Argo CD](https://img.shields.io/badge/Argo%20CD-2.6%2B-blue?logo=argo)](https://argo-cd.readthedocs.io/)
[![Helm](https://img.shields.io/badge/Helm-3.x-blue?logo=helm)](https://helm.sh/)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## Overview

This repository provides production-ready Argo CD `Application` manifests and Helm value overlays for deploying the JFrog Platform (Artifactory, Xray, Distribution, and more) via GitOps. Instead of running `helm upgrade --install` manually, Argo CD **owns** the release — monitoring for drift, auto-syncing on chart or values changes, and providing a dashboard for health and sync status.

### How It Works

```
┌──────────────────────┐         ┌─────────────────────┐
│   This Git Repo      │         │  JFrog Helm Repo    │
│                      │         │  charts.jfrog.io    │
│  customvalues.yaml   │         │                     │
│  sizing overlays     │         │  jfrog-platform     │
│  argocd-app.yaml     │         │  chart              │
└──────────┬───────────┘         └──────────┬──────────┘
           │                                │
           │    ┌──────────────────────┐     │
           └───►│      Argo CD         │◄────┘
                │                      │
                │  Watches both repos  │
                │  Renders Helm chart  │
                │  Syncs to cluster    │
                │  Self-heals drift    │
                └──────────┬───────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │  Kubernetes Cluster  │
                │                      │
                │  namespace:          │
                │  jfrog-platform      │
                │                      │
                │  Artifactory + Nginx │
                │  Xray (optional)     │
                │  Distribution (opt)  │
                └──────────────────────┘
```

Argo CD deploys the same Helm chart (`jfrog-platform`) from the same repo (`https://charts.jfrog.io`) using the same values you would pass to `helm upgrade --install`. The key difference is that Argo CD continuously reconciles the desired state from Git with the live state in the cluster.

## Features

- **GitOps-native** — All configuration is version-controlled, auditable, and PR-reviewable
- **Multi-source support** — Helm chart from JFrog's repo + values from your Git repo (Argo CD 2.6+)
- **Pre-built examples** — Evaluation, production, OpenShift, and multi-source configurations
- **Drift handling** — Built-in `ignoreDifferences` for known Helm chart quirks (TLS cert regeneration, StatefulSet mutation)
- **Helper scripts** — One-command Argo CD setup, secrets creation, and TLS provisioning
- **Upgrade-ready** — Clear upgrade path with hook management and version pinning

## Quick Start

### Prerequisites

| Requirement | Version | Notes |
|:---|:---|:---|
| Kubernetes cluster | 1.26+ | EKS, GKE, AKS, OpenShift 4.x, or local (minikube, kind, Rancher Desktop) |
| `kubectl` | 1.26+ | Configured to target your cluster |
| Argo CD | 2.6+ | 2.6+ required for multi-source Applications |
| Helm (optional) | 3.x | Only needed if you want to inspect charts locally |

**Deploy on AWS EKS:** For production-grade EKS (RDS, secrets, ALB), see **[docs/DEPLOY-EKS.md](docs/DEPLOY-EKS.md)** and the **[examples/eks/](examples/eks/)** example. Use `SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh` if the Argo CD install hits the 262144-byte annotation limit.

### 1. Install Argo CD

If Argo CD is not already installed on your cluster:

```bash
./scripts/setup-argocd.sh
```

On **EKS** (and other clusters that hit the ApplicationSet CRD annotation limit), use the filtered install:

```bash
SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh
```

(Requires [yq](https://github.com/mikefarah/yq). See [docs/DEPLOY-EKS.md](docs/DEPLOY-EKS.md) for full EKS steps.)

Or manually (full install):

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
```

### 2. Create Secrets

> **Never commit plaintext credentials to Git.** Create Kubernetes secrets before deploying.

For evaluation (bundled PostgreSQL, auto-generated keys):

```bash
kubectl create namespace jfrog-platform
```

For production, create secrets for database credentials, master/join keys, and licenses:

```bash
./scripts/create-secrets.sh
```

### 3. (Optional) Pre-create a Stable TLS Secret

The JFrog chart auto-generates a self-signed TLS certificate on every Helm render, causing persistent `OutOfSync` in Argo CD. To eliminate this drift:

```bash
./scripts/create-tls-secret.sh
```

The manifests in this repo already include `ignoreDifferences` as a fallback, but pre-creating the secret is the cleanest approach.

### 4. Fork and Customize

```bash
# Fork this repo, then clone your fork
git clone https://github.com/<YOUR_ORG>/jfrog-gitops-test.git
cd jfrog-gitops-test

# Copy the example that fits your environment
cp examples/evaluation/customvalues.yaml customvalues.yaml
# OR
cp examples/production/customvalues.yaml customvalues.yaml

# Edit to match your environment
vi customvalues.yaml

# Update the Argo CD Application to point to YOUR repo
vi argocd-app.yaml
# Change: repoURL: https://github.com/<YOUR_ORG>/jfrog-gitops-test.git
```

### 5. Deploy

```bash
kubectl apply -f argocd-app.yaml
```

### 6. Verify

```bash
# Watch sync status
kubectl get application jfrog-platform -n argocd -w

# Watch pods come up (Artifactory takes 3-5 minutes on first boot)
kubectl get pods -n jfrog-platform -w

# Verify Artifactory is reachable
kubectl port-forward svc/jfrog-platform-artifactory-nginx \
  -n jfrog-platform 8082:80

curl http://localhost:8082/artifactory/api/system/ping
# Expected: OK
```

Open the Argo CD dashboard:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## Repository Structure

```
.
├── argocd-app.yaml              # Main Argo CD Application manifest (multi-source)
├── customvalues.yaml            # Your Helm values (edit this)
├── examples/
│   ├── evaluation/              # Bundled DB, minimal resources
│   │   ├── argocd-app.yaml
│   │   └── customvalues.yaml
│   ├── production/              # External DB, secrets, sizing
│   │   ├── argocd-app.yaml
│   │   └── customvalues.yaml
│   ├── eks/                     # AWS EKS production (RDS, ALB-ready)
│   │   ├── argocd-app.yaml
│   │   └── customvalues.yaml
│   ├── openshift/               # OpenShift security context overrides
│   │   ├── argocd-app.yaml
│   │   └── customvalues.yaml
│   └── multi-source/            # Multi-source with sizing overlays
│       ├── argocd-app.yaml
│       └── customvalues.yaml
├── scripts/
│   ├── setup-argocd.sh          # Install Argo CD on your cluster
│   ├── create-secrets.sh        # Create Kubernetes secrets for JFrog Platform
│   └── create-tls-secret.sh     # Pre-create a stable TLS secret
├── .github/
│   └── workflows/
│       ├── validate.yaml        # CI: YAML lint, Helm template, scripts, dry-run
│       └── integration.yaml     # Optional: kind + Argo CD (manual trigger)
├── docs/
│   ├── DEPLOY-EKS.md            # Deploy on AWS EKS (production-grade, step-by-step)
│   ├── HELM-DOCS-COVERAGE.md    # Mapping to official Helm install/upgrade/uninstall docs
│   ├── INGRESS-ROUTE.md         # Expose platform (Ingress / ALB / OpenShift Route)
│   ├── TESTING.md               # How to test (CI, local, checklist before going public)
│   ├── TROUBLESHOOTING.md       # Common issues and fixes
│   ├── UNINSTALL.md             # Uninstall via Argo CD and cleanup
│   └── UPGRADING.md             # Upgrade procedures
├── CONTRIBUTING.md              # How to contribute
├── CODE_OF_CONDUCT.md           # Community guidelines
└── LICENSE                      # Apache 2.0
```

## Examples

| Example | Use Case | Argo CD Version | DB | Xray |
|:---|:---|:---|:---|:---|
| [evaluation](examples/evaluation/) | Local testing, PoC, demos | 2.4+ | Bundled PostgreSQL | Disabled |
| [production](examples/production/) | Production deployments | 2.6+ | External PostgreSQL | Enabled |
| [eks](examples/eks/) | **AWS EKS production** (RDS, ALB-ready) | 2.6+ | External (RDS) | Enabled |
| [openshift](examples/openshift/) | OpenShift 4.x clusters | 2.6+ | External PostgreSQL | Configurable |
| [multi-source](examples/multi-source/) | Full GitOps with sizing overlays | 2.6+ | Configurable | Configurable |

## Important Notes

### Disable Hooks for Fresh Installs

The JFrog Platform chart includes `pre-upgrade` Helm hooks (Jobs that validate existing secrets and RabbitMQ state). On a **fresh install**, these hooks **fail** because the resources they check don't exist yet. You **must** disable them:

```yaml
preUpgradeHook:
  enabled: false
upgradeHookSTSDelete:
  enabled: false
```

After the first successful deployment, re-enable them for future upgrades. See [docs/UPGRADING.md](docs/UPGRADING.md).

### Known Argo CD Drift Issues

The manifests include `ignoreDifferences` to handle two known sources of drift:

1. **Nginx TLS Certificate** — The chart auto-generates a self-signed cert on every render. Argo CD always sees a diff.
2. **StatefulSet VolumeClaimTemplates** — Kubernetes mutates the spec after creation.

For a cleaner solution, [pre-create a stable TLS secret](#3-optional-pre-create-a-stable-tls-secret).

## Relationship to official Helm documentation

This repo focuses on **deploying via Argo CD** (Application manifests, sync, drift, upgrade flow). It does **not** replace the full [JFrog Platform Helm documentation](https://jfrog.com/help/r/install-the-jfrog-platform-using-helm-chart). The same Helm chart and values are used; only the deployment mechanism differs.

| You need… | Use |
|:---|:---|
| Argo CD deploy, examples, scripts, Argo-specific troubleshooting/upgrade/uninstall | **This repo** ([README](README.md), [examples](examples/), [docs](docs/)) |
| Prerequisites, planning, external DB/filestore, licensing, production checklist, advanced options (TLS, HA, Xray RabbitMQ, etc.) | **Official Helm docs** (linked from [docs/HELM-DOCS-COVERAGE.md](docs/HELM-DOCS-COVERAGE.md)) |

**Full mapping:** [docs/HELM-DOCS-COVERAGE.md](docs/HELM-DOCS-COVERAGE.md) — every topic in the official "Install \| Upgrade \| Uninstall" and "Helm Charts for Advanced Users" sections is mapped to either this repo or the official doc link.

## Upgrading

To upgrade the JFrog Platform chart version:

1. Update `targetRevision` in `argocd-app.yaml`
2. Ensure `preUpgradeHook.enabled: true` in `customvalues.yaml`
3. Commit and push — Argo CD syncs automatically

See [docs/UPGRADING.md](docs/UPGRADING.md) for detailed upgrade procedures.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and fixes, including:

- Sync failures from pre-upgrade hooks
- Persistent OutOfSync status
- Database connection errors
- Jobs stuck in Terminating state

## Next steps after deploy

- **[Expose the platform](docs/INGRESS-ROUTE.md)** — Ingress (Kubernetes) or Route (OpenShift) for HTTPS.
- **Licensing** — [Official: Manage Licensing](https://jfrog.com/help/r/platform-helm-chart-manage-licensing).
- **[Upgrade](docs/UPGRADING.md)** — Argo CD flow; [official upgrade guide](https://jfrog.com/help/r/upgrade-jfrog-platform-using-helm-chart) for rollback and major versions.
- **[Uninstall](docs/UNINSTALL.md)** — Remove Application and optional PVC/external cleanup.
- **Advanced** — [Official: Helm Charts for Advanced Users](https://jfrog.com/help/r/helm-charts-for-advanced-users).

## How to run (step-by-step)

**New to this repo?** Follow **[docs/HOW-TO-RUN.md](docs/HOW-TO-RUN.md)** for copy-paste steps:

- **Path A: Local** — Evaluation on Rancher Desktop or kind (no external DB).
- **Path B: AWS EKS** — Production on EKS with RDS and secrets.

## Testing

Before making the repo public, run the automated checks and optionally the integration test:

- **Validate (CI):** On every push/PR, GitHub Actions run YAML lint, Helm template, script syntax check, and `kubectl apply --dry-run` on all manifests. See [Actions](https://github.com/nagarajuv-jfrog/jfrog-gitops-test/actions).
- **Integration (manual):** In the Actions tab, run the workflow **Integration (kind + Argo CD)** to deploy the evaluation example on a kind cluster and verify Argo CD syncs.
- **Local:** See [docs/TESTING.md](docs/TESTING.md) for local validation and a pre-public checklist.

## Contributing

We welcome contributions! Whether it's new examples, documentation improvements, bug fixes, or feature requests — please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Community

- **Issues** — [GitHub Issues](https://github.com/nagarajuv-jfrog/jfrog-gitops-test/issues)
- **Discussions** — [GitHub Discussions](https://github.com/nagarajuv-jfrog/jfrog-gitops-test/discussions)
- **JFrog Community** — [community.jfrog.com](https://community.jfrog.com/)
- **Argo CD Docs** — [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/)
- **JFrog Helm Charts** — [github.com/jfrog/charts](https://github.com/jfrog/charts)

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Acknowledgments

- [JFrog](https://jfrog.com/) for the JFrog Platform Helm charts
- [Argo CD](https://argoproj.github.io/cd/) for the GitOps continuous delivery engine
- The open-source community for feedback and contributions
