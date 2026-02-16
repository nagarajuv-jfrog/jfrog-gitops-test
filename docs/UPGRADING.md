# Upgrading JFrog Platform via Argo CD

This guide covers upgrading the JFrog Platform Helm chart when it is managed by Argo CD.

## Before you upgrade

1. **Re-enable hooks**  
   For upgrades (not fresh installs), the pre-upgrade hooks must run. In your values:

   ```yaml
   preUpgradeHook:
     enabled: true
   upgradeHookSTSDelete:
     enabled: true
   ```

2. **Bundled PostgreSQL**  
   If you use the bundled PostgreSQL subchart, add:

   ```yaml
   databaseUpgradeReady: true
   ```

   This acknowledges that the PostgreSQL subchart may be upgraded. See [Upgrading Bundled PostgreSQL](https://jfrog.com/help/r/helm-charts/) in the official docs.

3. **Backup**  
   Back up databases and any critical config/secrets before upgrading.

## Upgrade steps

### 1. Update chart version

**Single-source Application (chart only):**  
Edit the Application manifest and set a new `targetRevision`:

```yaml
spec:
  source:
    chart: jfrog-platform
    targetRevision: "11.4.0"   # change to desired version
```

**Multi-source Application (chart + Git values):**  
Update `targetRevision` in the chart source:

```yaml
spec:
  sources:
    - repoURL: https://charts.jfrog.io
      chart: jfrog-platform
      targetRevision: "11.4.0"   # change to desired version
      helm:
        valueFiles:
          - $values/customvalues.yaml
    - repoURL: https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
      targetRevision: main
      ref: values
```

To see available chart versions:

```bash
helm repo add jfrog https://charts.jfrog.io
helm search repo jfrog/jfrog-platform --versions
```

### 2. Apply the change

**If you apply the Application manifest locally:**

```bash
# After editing argocd-app.yaml with the new targetRevision
kubectl apply -f argocd-app.yaml
```

**If Argo CD watches your Git repo (GitOps):**

```bash
# After editing argocd-app.yaml and/or customvalues.yaml
git add argocd-app.yaml customvalues.yaml
git commit -m "Upgrade JFrog Platform chart to 11.4.0"
git push origin main
```

Argo CD will pick up the change on the next poll (or trigger a refresh):

```bash
kubectl patch application jfrog-platform -n argocd --type=merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### 3. Monitor

- **Sync status:**  
  `kubectl get application jfrog-platform -n argocd -w`

- **Pods:**  
  `kubectl get pods -n jfrog-platform -w`

- **Argo CD UI:**  
  Port-forward `argocd-server` and watch sync and health.

Pods will restart with the new image version. Artifactory can take a few minutes to become Ready.

### 4. Verify

- Ping Artifactory:  
  `curl http://localhost:8082/artifactory/api/system/ping` (after port-forward)
- Check version:  
  `curl -u admin:password http://localhost:8082/artifactory/api/system/version`
- Confirm chart revision in spec:  
  `kubectl get application jfrog-platform -n argocd -o jsonpath='{.spec.sources[0].targetRevision}'` (multi-source) or `.spec.source.targetRevision` (single-source)

## Post-install: re-enable hooks (reminder)

After the **first** successful deployment, re-enable hooks so they run on **future** upgrades:

```yaml
preUpgradeHook:
  enabled: true
upgradeHookSTSDelete:
  enabled: true
```

Update your values (in Git or in the Application manifest) and apply/commit. Do not leave hooks disabled for production upgrades.

## Rollback

If you need to roll back:

1. Set `targetRevision` back to the previous chart version in `argocd-app.yaml`.
2. If you changed values, revert those in Git or in the manifest.
3. Apply or push; Argo CD will sync to the previous revision.
4. If needed, use Helm/Argo CD rollback or restore from backup for data.

## Major version upgrades

For major chart or product version jumps (e.g. 10.x → 11.x), always:

- Read the official [release notes](https://www.jfrog.com/confluence/) and [Helm upgrade docs](https://jfrog.com/help/r/helm-charts/).
- Test in a non-production environment first.
- Follow any documented migration or schema steps for DB and config.

## References

- [JFrog Platform upgrade documentation](https://jfrog.com/help/r/upgrade-jfrog-platform/)
- [Helm charts for advanced users](https://jfrog.com/help/r/helm-charts-for-advanced-users/)
- [Argo CD Application spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
