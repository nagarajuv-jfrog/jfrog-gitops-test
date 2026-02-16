# Uninstall JFrog Platform (Argo CD)

To remove the JFrog Platform deployed via Argo CD, delete the Argo CD Application. Optionally remove persistent data and external resources.

## Remove the Argo CD Application

```bash
kubectl delete application jfrog-platform -n argocd
```

This deletes the Application and **all resources it manages** (pods, services, StatefulSets, etc.). It does **not** delete PVCs or resources outside the cluster.

## Remove persistent data (optional)

If you want to **permanently delete all data** in the cluster (PVCs):

```bash
# List PVCs
kubectl get pvc -n jfrog-platform

# Delete all PVCs in the namespace
kubectl delete pvc --all -n jfrog-platform
```

**Warning:** Deleting PVCs removes all artifact and configuration data on those volumes. Ensure you have backups if you might need this data.

## External resources not removed

Argo CD and Kubernetes do **not** remove:

- **External database** (e.g. RDS, Azure Database for PostgreSQL) — delete or retain via your cloud provider.
- **Object storage** (S3, GCS, Azure Blob) — buckets and contents remain; remove or archive separately.
- **Secrets in external managers** — keys in Vault, AWS Secrets Manager, etc. are not removed.

Clean these up manually per your organization's policies when you no longer need the platform.

## Optionally remove the namespace

If the namespace was only used for JFrog Platform:

```bash
kubectl delete namespace jfrog-platform
```

Do this only after removing the Application and any PVCs you intend to delete.

## Before you uninstall

**Back up** data and configuration if you might need them later. Export config, snapshot the database and filestore if used, and store licenses. See the official [Backup and Disaster Recovery](https://jfrog.com/help/r/planning-backup-and-disaster-recovery-planning) and [Uninstall JFrog Platform](https://jfrog.com/help/r/uninstall-jfrog-platform-using-helm-chart) documentation.
