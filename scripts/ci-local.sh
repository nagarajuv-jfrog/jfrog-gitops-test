#!/usr/bin/env bash
# Run the same checks as the Validate workflow locally (no push required).
# Prerequisites: Python + yamllint, Helm 3, optional: kind + kubectl for dry-run.
set -euo pipefail

CHART_VERSION="${CHART_VERSION:-11.4.2}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== 1. YAML lint ==="
if command -v yamllint &>/dev/null; then
  yamllint argocd-app.yaml customvalues.yaml
  yamllint examples/
  yamllint .github/workflows/
  echo "yamllint OK"
else
  echo "Skip: yamllint not found (pip install yamllint)"
fi

echo ""
echo "=== 2. Helm template ==="
if command -v helm &>/dev/null; then
  helm repo add jfrog https://charts.jfrog.io 2>/dev/null || true
  helm repo update jfrog
  for name in root evaluation production eks openshift multi-source; do
    case "$name" in
      root)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f customvalues.yaml --namespace jfrog-platform >/dev/null
        ;;
      evaluation)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f examples/evaluation/customvalues.yaml --namespace jfrog-platform >/dev/null
        ;;
      production)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f examples/production/customvalues.yaml --namespace jfrog-platform >/dev/null
        ;;
      eks)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f examples/eks/customvalues.yaml --namespace jfrog-platform >/dev/null
        ;;
      openshift)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f examples/openshift/customvalues.yaml --namespace jfrog-platform >/dev/null
        ;;
      multi-source)
        helm template jfrog-platform jfrog/jfrog-platform --version "$CHART_VERSION" \
          -f examples/multi-source/customvalues.yaml \
          -f examples/multi-source/sizing/platform-medium.yaml \
          --namespace jfrog-platform >/dev/null
        ;;
    esac
    echo "  helm template ($name) OK"
  done
else
  echo "Skip: helm not found"
fi

echo ""
echo "=== 3. Shell script syntax (bash -n) ==="
shopt -s nullglob
for f in scripts/*.sh; do
  bash -n "$f" || { echo "Syntax error in $f"; exit 1; }
done
echo "  All scripts OK"

echo ""
echo "=== 4. kubectl dry-run (optional) ==="
if command -v kubectl &>/dev/null && command -v kind &>/dev/null; then
  if ! kind get kubeconfig &>/dev/null; then
    echo "  No kind cluster running. Create one with: kind create cluster"
    echo "  Then install the Application CRD and re-run this script, or run:"
    echo "    kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml"
    echo "    kubectl apply --dry-run=client -f argocd-app.yaml"
    echo "    for f in examples/*/argocd-app.yaml; do kubectl apply --dry-run=client -f \"\$f\"; done"
  else
    kubectl apply --dry-run=client -f argocd-app.yaml
    for f in examples/evaluation/argocd-app.yaml examples/production/argocd-app.yaml examples/eks/argocd-app.yaml examples/openshift/argocd-app.yaml examples/multi-source/argocd-app.yaml; do
      kubectl apply --dry-run=client -f "$f"
    done
    echo "  kubectl dry-run OK"
  fi
else
  echo "  Skip: kind and/or kubectl not in PATH"
fi

echo ""
echo "=== Done. Run 'git push' to trigger the Validate workflow on GitHub. ==="
