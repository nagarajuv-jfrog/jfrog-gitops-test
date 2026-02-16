#!/usr/bin/env bash
# Create Kubernetes secrets for JFrog Platform (DB, master/join keys).
# Do NOT commit real credentials. Use env vars or prompt.
# Usage: ./scripts/create-secrets.sh
# Set: DB_HOST, DB_USER, DB_PASSWORD, MASTER_KEY, JOIN_KEY (optional)
set -euo pipefail

NAMESPACE="${JFROG_NAMESPACE:-jfrog-platform}"
SECRET_KEYS="${SECRET_KEYS_NAME:-my-platform-keys}"
ARTIFACTORY_DB_SECRET="${ARTIFACTORY_DB_SECRET:-artifactory-db-secret}"
XRAY_DB_SECRET="${XRAY_DB_SECRET:-xray-db-secret}"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Master key and join key (required for multi-node / Xray)
if [[ -z "${MASTER_KEY:-}" ]] || [[ -z "${JOIN_KEY:-}" ]]; then
  echo "MASTER_KEY and JOIN_KEY not set. Creating placeholder secret; replace with real values."
  echo "Generate keys: https://jfrog.com/help/r/jfrog-platform-administration-documentation/master-key"
  kubectl create secret generic "${SECRET_KEYS}" -n "${NAMESPACE}" \
    --from-literal=master-key="${MASTER_KEY:-placeholder-master-key}" \
    --from-literal=join-key="${JOIN_KEY:-placeholder-join-key}" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  kubectl create secret generic "${SECRET_KEYS}" -n "${NAMESPACE}" \
    --from-literal=master-key="${MASTER_KEY}" \
    --from-literal=join-key="${JOIN_KEY}" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

# Artifactory DB: user/password in secret; URL in values
if [[ -n "${ARTIFACTORY_DB_USER:-}" ]] && [[ -n "${ARTIFACTORY_DB_PASSWORD:-}" ]]; then
  kubectl create secret generic "${ARTIFACTORY_DB_SECRET}" -n "${NAMESPACE}" \
    --from-literal=user="${ARTIFACTORY_DB_USER}" \
    --from-literal=password="${ARTIFACTORY_DB_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Created ${ARTIFACTORY_DB_SECRET}. Set artifactory.artifactory.database.url and secretName in values."
else
  echo "Skip Artifactory DB secret (set ARTIFACTORY_DB_USER and ARTIFACTORY_DB_PASSWORD to create)."
fi

# Xray DB: optional URL or user/password
if [[ -n "${XRAY_DB_URL:-}" ]]; then
  kubectl create secret generic "${XRAY_DB_SECRET}" -n "${NAMESPACE}" \
    --from-literal=url="${XRAY_DB_URL}" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Created ${XRAY_DB_SECRET} with url."
elif [[ -n "${XRAY_DB_USER:-}" ]] && [[ -n "${XRAY_DB_PASSWORD:-}" ]]; then
  kubectl create secret generic "${XRAY_DB_SECRET}" -n "${NAMESPACE}" \
    --from-literal=user="${XRAY_DB_USER}" \
    --from-literal=password="${XRAY_DB_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Created ${XRAY_DB_SECRET}. Set xray.database.url and secretName in values."
else
  echo "Skip Xray DB secret (set XRAY_DB_URL or XRAY_DB_USER/XRAY_DB_PASSWORD to create)."
fi

echo "Secrets created in namespace: ${NAMESPACE}"
