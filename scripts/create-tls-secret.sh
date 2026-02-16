#!/usr/bin/env bash
# Pre-create a stable TLS secret for JFrog Platform Nginx to avoid Argo CD OutOfSync.
# For production, use cert-manager or your PKI instead of this self-signed cert.
# Usage: ./scripts/create-tls-secret.sh [CN]
# Example: ./scripts/create-tls-secret.sh jfrog-platform.local
set -euo pipefail

CN="${1:-jfrog-platform.local}"
NAMESPACE="${JFROG_NAMESPACE:-jfrog-platform}"
SECRET_NAME="${TLS_SECRET_NAME:-jfrog-platform-tls}"
DIR="${TMPDIR:-/tmp}/jfrog-tls-$$"
mkdir -p "${DIR}"
trap 'rm -rf "${DIR}"' EXIT

echo "Generating self-signed certificate (CN=${CN})..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${DIR}/tls.key" -out "${DIR}/tls.crt" \
  -subj "/CN=${CN}"

echo "Creating namespace ${NAMESPACE} if needed..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating TLS secret: ${SECRET_NAME} in ${NAMESPACE}"
kubectl create secret tls "${SECRET_NAME}" \
  --cert="${DIR}/tls.crt" --key="${DIR}/tls.key" \
  -n "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Done. Add to your Helm values:"
echo "  artifactory:"
echo "    nginx:"
echo "      tlsSecretName: ${SECRET_NAME}"
