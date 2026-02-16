#!/usr/bin/env bash
# Install Argo CD on the current Kubernetes cluster.
# Usage: ./scripts/setup-argocd.sh
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
INSTALL_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "Creating namespace: ${ARGOCD_NAMESPACE}"
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Argo CD install manifest..."
kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${INSTALL_MANIFEST}"

echo "Waiting for Argo CD pods to be Ready (timeout 180s)..."
kubectl wait --for=condition=Ready pods --all -n "${ARGOCD_NAMESPACE}" --timeout=180s

echo "Argo CD is installed. Get the initial admin password with:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
echo "Port-forward the server: kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
echo "Then open https://localhost:8080 (username: admin)"
