#!/usr/bin/env bash
# Install Argo CD on the current Kubernetes cluster.
# Usage: ./scripts/setup-argocd.sh
# Set SKIP_APPLICATIONSET_CRD=1 to install without the ApplicationSet CRD (avoids 262144-byte annotation limit on EKS and others).
#   Requires yq: https://github.com/mikefarah/yq (e.g. brew install yq)
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
INSTALL_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "Creating namespace: ${ARGOCD_NAMESPACE}"
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if [[ "${SKIP_APPLICATIONSET_CRD:-0}" == "1" ]]; then
  if ! command -v yq &>/dev/null; then
    echo "SKIP_APPLICATIONSET_CRD=1 requires yq. Install with: brew install yq"
    echo "Or run the filtered install manually: see docs/DEPLOY-EKS.md or docs/TESTING.md"
    exit 1
  fi
  echo "Installing Argo CD without ApplicationSet CRD (filtered manifest)..."
  curl -fsSL -o /tmp/argocd-install.yaml "${INSTALL_MANIFEST}"
  yq eval-all 'select(.kind != "CustomResourceDefinition" or .metadata.name != "applicationsets.argoproj.io")' /tmp/argocd-install.yaml > /tmp/argocd-install-filtered.yaml
  kubectl apply -n "${ARGOCD_NAMESPACE}" -f /tmp/argocd-install-filtered.yaml
  rm -f /tmp/argocd-install.yaml /tmp/argocd-install-filtered.yaml
else
  echo "Applying Argo CD install manifest..."
  kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${INSTALL_MANIFEST}"
fi

echo "Waiting for Argo CD pods to be Ready (timeout 180s)..."
kubectl wait --for=condition=Ready pods --all -n "${ARGOCD_NAMESPACE}" --timeout=180s

echo "Argo CD is installed. Get the initial admin password with:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
echo "Port-forward the server: kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
echo "Then open https://localhost:8080 (username: admin)"
