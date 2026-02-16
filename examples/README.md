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

1. Choose the example that fits your environment (evaluation, eks, production, openshift, or multi-source).
2. For multi-source examples (eks, production, openshift, multi-source): edit that example’s `argocd-app.yaml` and set `<YOUR_ORG>` / `<YOUR_REPO>` to your Git repo URL. Values are read from the same example directory (no copying to repo root).
3. Edit that example’s `customvalues.yaml` (DB URLs, secrets, sizing). Never commit credentials.
4. Create required secrets when needed (see [../scripts/](../scripts/) and main [../README.md](../README.md)).
5. From the repo root, apply: `kubectl apply -f examples/<name>/argocd-app.yaml` (e.g. `kubectl apply -f examples/eks/argocd-app.yaml`).

For fresh installs, ensure `preUpgradeHook.enabled: false` and `upgradeHookSTSDelete.enabled: false` in values; re-enable after first successful deploy (see [../docs/UPGRADING.md](../docs/UPGRADING.md)).
