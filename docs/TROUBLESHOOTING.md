# Troubleshooting Argo CD Deployments

Common issues when deploying the JFrog Platform with Argo CD and how to fix them.

## Sync and deployment issues

### `applications.argoproj.io` not found

**Cause:** Argo CD is not installed. The `Application` CRD does not exist.

**Fix:** Install Argo CD first:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
```

Or use the helper script: `./scripts/setup-argocd.sh`

---

### Sync fails — pre-upgrade hook Jobs in Error

**Cause:** The JFrog chart runs Helm pre-upgrade hooks (Jobs that check for existing secrets and RabbitMQ state). On a **fresh install**, those resources do not exist yet, so the hooks fail and block sync.

**Fix:** Disable the hooks for the initial deployment. In your values:

```yaml
preUpgradeHook:
  enabled: false
upgradeHookSTSDelete:
  enabled: false
```

After the first successful deploy, re-enable them for future upgrades. See [UPGRADING.md](UPGRADING.md).

---

### Sync stuck — Jobs in Terminating state

**Cause:** Argo CD adds a hook finalizer (`argocd.argoproj.io/hook-finalizer`) to hook Jobs. Sometimes Jobs get stuck in Terminating.

**Fix:** Remove the finalizer so the Job can be deleted:

```bash
kubectl patch job <JOB_NAME> -n jfrog-platform --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
```

Replace `<JOB_NAME>` with the actual Job name (e.g. from `kubectl get jobs -n jfrog-platform`).

---

### Synced / Progressing for a long time

**Cause:** Artifactory has many containers and startup probes. On first boot it can take **3–5 minutes** to become Ready.

**Fix:** Wait and watch pods. Once all pods in `jfrog-platform` are Running and Ready, Argo CD will transition the Application to Healthy.

```bash
kubectl get pods -n jfrog-platform -w
```

---

### Only `jfrog-platform-artifactory-nginx` is Progressing

**Cause:** The Artifactory nginx Deployment is the front proxy; its readiness probe depends on the Artifactory backend. Until the Artifactory pod is Ready, nginx stays not ready and Argo CD shows the nginx resource as **Progressing**.

**Fix:** This is normal on first deploy. Wait for the Artifactory pod to become Ready (often 3–5 minutes). Then nginx will become Ready and the Application will show Healthy.

```bash
# Watch until Artifactory is Ready, then nginx will follow
kubectl get pods -n jfrog-platform -w
```

If it stays Progressing for more than ~10 minutes, check Artifactory logs and readiness:

```bash
kubectl describe pod -n jfrog-platform -l app=artifactory
kubectl logs -n jfrog-platform -l app=artifactory -c artifactory --tail=50
```

---

### Persistent OutOfSync — Nginx certificate

**Cause:** The JFrog chart auto-generates a self-signed TLS certificate on every Helm render. Argo CD compares the new manifest to the live Secret and always sees a diff.

**Fix (choose one):**

1. **ignoreDifferences (already in repo manifests)**  
   The provided Application manifests include `ignoreDifferences` for the Nginx certificate Secret. If you use those manifests, this drift is ignored.

2. **Pre-create a stable TLS secret (recommended for production)**  
   Create the TLS secret once and reference it in values so the chart does not generate a new one:

   ```bash
   ./scripts/create-tls-secret.sh jfrog-platform.local
   ```

   In values:

   ```yaml
   artifactory:
     nginx:
       tlsSecretName: jfrog-platform-tls
   ```

   For production, use cert-manager or your PKI instead of a self-signed cert.

---

### Persistent OutOfSync — StatefulSet

**Cause:** Kubernetes can mutate `volumeClaimTemplates` (e.g. resources) after the StatefulSet is created. Argo CD then sees a diff.

**Fix:** The provided Application manifests include `ignoreDifferences` with `jqPathExpressions` for `.spec.volumeClaimTemplates[].spec`. If you copied an example, ensure this block is present. You can also ignore resource fields on the pod template if your cluster mutates them:

```yaml
ignoreDifferences:
  - group: apps
    kind: StatefulSet
    name: jfrog-platform-artifactory
    jqPathExpressions:
      - .spec.volumeClaimTemplates[].spec
      - .spec.template.spec.containers[].resources
      - .spec.template.spec.initContainers[].resources
```

---

## Application and runtime issues

### Database connection errors

**Cause:** Wrong DB URL, credentials, or network (DB not reachable from the cluster).

**Fix:**

1. Verify the database URL and credentials. Use Kubernetes secrets; never put plaintext credentials in Git.
2. From a pod in the same namespace, test connectivity:

   ```bash
   kubectl run -it --rm debug --image=postgres:15 -n jfrog-platform -- \
     psql "postgresql://USER:PASSWORD@DB_HOST:5432/artifactory" -c "SELECT 1"
   ```

3. Check Artifactory/Xray logs:

   ```bash
   kubectl logs -n jfrog-platform -l app=artifactory -c artifactory --tail=100
   ```

4. See the official [JFrog Helm chart documentation](https://jfrog.com/help/r/helm-charts/) and [Troubleshooting](https://jfrog.com/help/r/platform-helm-chart-troubleshooting) for DB and filestore setup.

---

### Argo CD does not see my Git/values changes

**Cause:** Argo CD polls Git every few minutes by default, or the repo might not be configured.

**Fix:** Trigger a refresh:

```bash
kubectl patch application jfrog-platform -n argocd --type=merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

In the Argo CD UI, use "Refresh" (hard refresh if needed). Ensure the Application source points to the correct repo and branch.

---

### How do I confirm the chart version deployed?

For Helm chart sources, Argo CD does not set `status.sync.revision`. Use the spec instead:

```bash
# Single-source Application
kubectl get application jfrog-platform -n argocd -o jsonpath='{.spec.source.targetRevision}' && echo

# Multi-source Application
kubectl get application jfrog-platform -n argocd -o jsonpath='{.spec.sources[0].targetRevision}' && echo
```

---

## Uninstall

To remove the JFrog Platform deployed via Argo CD:

```bash
kubectl delete application jfrog-platform -n argocd
```

This deletes the Application and all resources it manages. PVCs and external resources (database, object storage) are **not** removed. See the official [Uninstall JFrog Platform](https://jfrog.com/help/r/uninstall-jfrog-platform/) documentation for full cleanup.

---

## Additional resources

- [Argo CD Helm chart sources](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [JFrog Helm charts](https://github.com/jfrog/charts)
- [JFrog Platform documentation](https://jfrog.com/help/r/jfrog-platform-administration-documentation/)
