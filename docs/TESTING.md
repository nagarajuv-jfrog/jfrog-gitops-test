# Testing Before Going Public

Use these checks to validate the repo before exposing it publicly.

## 1. GitHub Actions (automated)

### Validate workflow (runs on every push and PR)

- **YAML lint** — All `argocd-app.yaml`, `customvalues.yaml`, and example YAML checked with `yamllint`.
- **Helm template** — `helm template` run for root and each example (evaluation, production, OpenShift, multi-source) to ensure values render without errors.
- **Shell scripts** — `bash -n` syntax check and optional ShellCheck on `scripts/*.sh`.
- **kubectl dry-run** — Application manifests applied with `kubectl apply --dry-run=client` to catch invalid Kubernetes/Argo CD YAML.

**How to run:** Push or open a PR to `main`/`master`. Check the **Validate** workflow in the Actions tab.

### Integration workflow (manual)

- Creates a **kind** cluster, installs **Argo CD**, applies the **evaluation** Application, and waits for **Synced** (up to 5 minutes).
- Confirms that Argo CD can pull the chart, render templates, and sync resources. Pods may not become Healthy if image pull requires auth.

**How to run:** In GitHub, go to **Actions** → **Integration (kind + Argo CD)** → **Run workflow** → **Run workflow**.

**Note:** If JFrog container images require authentication, the integration job may show ImagePullBackOff; the Sync step can still succeed and validates the manifests.

## 2. Run CI checks locally

Run the same checks as the Validate workflow without pushing:

```bash
./scripts/ci-local.sh
```

**Prerequisites:** Python (for `yamllint`), Helm 3. Optional: `kind` and `kubectl` for the dry-run step (if a kind cluster is running with the Application CRD installed).

- To install yamllint: `pip install yamllint`
- To install Helm: see [helm.sh](https://helm.sh/docs/intro/install/)
- To install kind and kubectl: see [kind.sigs.k8s.io](https://kind.sigs.k8s.io/)

The script runs: yaml lint, helm template (all examples, chart version 11.4.0), shell syntax check, and optionally kubectl dry-run when a cluster is available.

## 3. Local validation (manual commands)

Alternatively, run these on your machine before pushing:

```bash
# YAML lint (install: pip install yamllint)
yamllint argocd-app.yaml customvalues.yaml examples/ .github/workflows/

# Helm template (install Helm 3, add repo: helm repo add jfrog https://charts.jfrog.io && helm repo update jfrog)
helm template jfrog-platform jfrog/jfrog-platform --version "11.4.0" -f customvalues.yaml --namespace jfrog-platform

# Script syntax
shopt -s nullglob; for f in scripts/*.sh; do bash -n "$f"; done

# Argo CD manifest dry-run (requires kubectl + Application CRD)
kubectl apply --dry-run=client -f argocd-app.yaml
for f in examples/*/argocd-app.yaml; do kubectl apply --dry-run=client -f "$f"; done
```

## 4. Local integration test (with cluster)

### Option A: Rancher Desktop (Mac)

Use your existing Rancher Desktop Kubernetes cluster.

**Prerequisites**

- [Rancher Desktop](https://rancherdesktop.io/) installed; cluster running (k3s or RKE2).
- `kubectl` in PATH (Rancher Desktop usually configures this).

**Steps**

```bash
# 1. Ensure cluster is up and kubectl targets it
kubectl cluster-info

# 2. Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 3. Deploy the evaluation Application
kubectl apply -f examples/evaluation/argocd-app.yaml

# 4. Watch sync status (Ctrl+C to stop)
kubectl get application jfrog-platform -n argocd -w
```

In another terminal, watch JFrog Platform pods (Artifactory can take 3–5 minutes to become Ready):

```bash
kubectl get pods -n jfrog-platform -w
```

**Note:** If you see `metadata.annotations: Too long: may not be more than 262144 bytes`, use `SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh` (requires [yq](https://github.com/mikefarah/yq)).

**Clean up**

```bash
kubectl delete application jfrog-platform -n argocd
kubectl delete namespace jfrog-platform
# To remove Argo CD: kubectl delete namespace argocd
```

---

### Option B: kind (Docker + kubectl)

If you have **Docker** and **kubectl**:

```bash
# Create kind cluster (install: https://kind.sigs.k8s.io/)
kind create cluster

# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s

# Deploy evaluation example
kubectl apply -f examples/evaluation/argocd-app.yaml

# Watch sync status
kubectl get application jfrog-platform -n argocd -w

# In another terminal, watch pods (may take 3–5 min for Artifactory)
kubectl get pods -n jfrog-platform -w
```

Clean up: `kind delete cluster`.

## 5. Checklist before making the repo public

- [ ] **Validate** workflow is green on `main` (push and/or open a PR and merge).
- [ ] **Integration** workflow runs successfully when triggered manually (optional but recommended).
- [ ] No secrets or credentials in the repo (double-check with `git log` and search for passwords/keys).
- [ ] README, CONTRIBUTING, and LICENSE are in place and accurate.
- [ ] Replace placeholder URLs (e.g. `nagarajuv-jfrog/jfrog-gitops-test`) with your org/repo if needed.
- [ ] `.gitignore` excludes `tls.crt`, `tls.key`, and any local secret files.
