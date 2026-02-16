# Examples

Ready-to-use Argo CD Application manifests and Helm value overlays for different deployment scenarios.

| Example | Use case | Argo CD | DB | Notes |
|:---|:---|:---|:---|:---|
| [evaluation](evaluation/) | PoC, demos, local testing | 2.4+ | Bundled PostgreSQL | Single source, inline values |
| [production](production/) | Production with external DB | 2.6+ | External | Multi-source, secrets |
| [eks](eks/) | **AWS EKS production** | 2.6+ | External (RDS) | Multi-source, RDS, ALB-ready |
| [openshift](openshift/) | OpenShift 4.x | 2.6+ | External | Security context overrides |
| [multi-source](multi-source/) | Full GitOps with overlays | 2.6+ | Configurable | valueFiles + sizing overlay |

## How to use

1. Copy the `argocd-app.yaml` and `customvalues.yaml` from the example that fits your environment.
2. Replace `<YOUR_ORG>` / `<YOUR_REPO>` in `argocd-app.yaml` with your Git repo URL.
3. Edit `customvalues.yaml` (DB URLs, secrets, sizing). Never commit credentials.
4. Create required secrets (see [../scripts/](../scripts/) and main [../README.md](../README.md)).
5. Apply: `kubectl apply -f argocd-app.yaml`

For fresh installs, ensure `preUpgradeHook.enabled: false` and `upgradeHookSTSDelete.enabled: false` in values; re-enable after first successful deploy (see [../docs/UPGRADING.md](../docs/UPGRADING.md)).
