# Coverage vs. Official JFrog Platform Helm Documentation

This page maps the **official JFrog Platform Helm documentation** (Install | Upgrade | Uninstall and Advanced) to what this GitOps repo provides. Use it to see what is covered here and what to follow in the official docs.

## Summary

| Area | GitOps repo | Official Helm docs |
|:---|:---|:---|
| **Deploy mechanism** | ✅ Full (Argo CD Application, examples, scripts) | N/A (Helm CLI) |
| **Prerequisites & planning** | Link only | ✅ Full |
| **External DB / filestore** | Examples reference secrets; values same as Helm | ✅ Full |
| **Configure custom values** | ✅ Examples + overlays | ✅ Full reference |
| **Production readiness** | Link only | ✅ Full |
| **Expose (Ingress / Route)** | ✅ [INGRESS-ROUTE.md](INGRESS-ROUTE.md) | ✅ Full |
| **Licensing** | Link only | ✅ Full |
| **Upgrade** | ✅ [UPGRADING.md](UPGRADING.md) (Argo CD flow) | ✅ Full (procedure, rollback, major) |
| **Uninstall** | ✅ [UNINSTALL.md](UNINSTALL.md) (Argo CD + cleanup) | ✅ Full |
| **Troubleshooting** | ✅ [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (Argo CD–specific) | ✅ Full (general Helm) |
| **Advanced customizations** | Link only | ✅ Full (TLS, volumes, HA, Xray, etc.) |

**Bottom line:** This repo covers **everything that is specific to Argo CD** (deploy, sync, drift, upgrade flow, uninstall). Everything that is **the same as with Helm** (prerequisites, DB/filestore config, licensing, TLS, HA, advanced options) is documented in the official Helm docs; we link to them and use the same values.

---

## Install workflow (official doc order)

Official flow: Deployment overview → Prerequisites → Planning → External resources → Configure values → Production checklist → **Add and deploy** → Expose (Ingress) → Manage licensing.

| Step | Official topic | This repo |
|:---|:---|:---|
| 1 | Deployment overview | See [README](../README.md). For architecture, sizing, and diagrams → official [Deployment workflow](https://jfrog.com/help/r/platform-deployment-workflow-helm) and [Reference Architecture](https://jfrog.com/reference-architecture/). |
| 2 | Prerequisites (K8s, Helm, storage, license, network) | Not duplicated. → Official [Prerequisites](https://jfrog.com/help/r/platform-helm-chart-prerequisites). |
| 3 | Planning (DB, filestore, HA, backup, sizing) | Not duplicated. → Official [Planning](https://jfrog.com/help/r/platform-helm-chart-planning), [Sizing](https://jfrog.com/reference-architecture/). |
| 4 | External resources (PostgreSQL, S3/GCS/Azure) | Same values as Helm; we use secrets. → Official [External database](https://jfrog.com/help/r/platform-helm-chart-external-database), [External filestore](https://jfrog.com/help/r/platform-helm-chart-external-file-store-binary-storage). |
| 5 | Configure custom values | ✅ [Examples](../examples/) (evaluation, production, OpenShift, multi-source). Full reference → Official [Configure custom values](https://jfrog.com/help/r/platform-helm-chart-configure-custom-values). |
| 6 | Production readiness checklist | Not duplicated. → Official [Production readiness](https://jfrog.com/help/r/platform-helm-chart-production-readiness-checklist). |
| 7 | **Add and deploy** | ✅ **Fully covered here:** [README](../README.md), [examples](../examples/), [scripts](../scripts/), Argo CD–specific [TROUBLESHOOTING](TROUBLESHOOTING.md). Official [Argo CD doc](https://jfrog.com/help/r/install-jfrog-platform-using-helm-chart-argo-cd) aligns with this repo. |
| 8 | Expose (Ingress / Load balancer / Route) | ✅ [INGRESS-ROUTE.md](INGRESS-ROUTE.md) (Kubernetes Ingress + OpenShift Route). Official [Access platform](https://jfrog.com/help/r/platform-helm-chart-access-platform-ingress-load-balancer). |
| 9 | Manage licensing | Not duplicated. → Official [Manage licensing](https://jfrog.com/help/r/platform-helm-chart-manage-licensing). |

---

## Upgrade

| Topic | This repo | Official |
|:---|:---|:---|
| Argo CD upgrade flow (targetRevision, hooks, refresh) | ✅ [UPGRADING.md](UPGRADING.md) | — |
| Chart upgrade procedure, rollback, major (10.x→11.x), bundled PostgreSQL | Link only | ✅ [Upgrade JFrog Platform](https://jfrog.com/help/r/upgrade-jfrog-platform-using-helm-chart) |

---

## Uninstall

| Topic | This repo | Official |
|:---|:---|:---|
| Remove Argo CD Application | ✅ [UNINSTALL.md](UNINSTALL.md) | — |
| PVC and external resource cleanup | ✅ [UNINSTALL.md](UNINSTALL.md) (summary + link) | ✅ [Uninstall JFrog Platform](https://jfrog.com/help/r/uninstall-jfrog-platform-using-helm-chart) |

---

## Troubleshooting

| Topic | This repo | Official |
|:---|:---|:---|
| Argo CD–specific (sync, hooks, OutOfSync, refresh) | ✅ [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | — |
| General Helm/platform (DB, logs, support) | Link only | ✅ [Platform Helm chart troubleshooting](https://jfrog.com/help/r/platform-helm-chart-troubleshooting) |

---

## Advanced Helm customizations

All of these are **the same values** whether you use `helm upgrade --install` or Argo CD. We do not duplicate the guides; use the official docs and put the same values in your `customvalues.yaml` (or overlays).

| Category | Official docs |
|:---|:---|
| **All products** | [Establish TLS](https://jfrog.com/help/r/establish-tls-in-artifactory-and-jfrog-platform), [System YAML override](https://jfrog.com/help/r/override-the-default-system-yaml-file-in-helm-installation), [Custom volumes](https://jfrog.com/help/r/add-custom-volumes-in-helm-installation), [Custom sidecars](https://jfrog.com/help/r/add-custom-sidecars-containers-in-helm-installations), [Custom init containers](https://jfrog.com/help/r/add-custom-init-containers-in-helm-installation), [Custom secrets](https://jfrog.com/help/r/use-custom-secrets-in-helm-installation), [Unified secret](https://jfrog.com/help/r/use-unified-secret-in-helm-installation), [Circle of Trust certs](https://jfrog.com/help/r/add-circle-of-trust-certificates), [Auto-generated passwords](https://jfrog.com/help/r/auto-generated-passwords-internal-postgresql) |
| **Artifactory** | [Licenses via secrets](https://jfrog.com/help/r/add-licenses-using-secrets), [Security](https://jfrog.com/help/r/security-related-issues), [Ingress behind LB](https://jfrog.com/help/r/run-ingress-behind-another-load-balancer), [Advanced storage](https://jfrog.com/help/r/advanced-storage-options), [Extensions](https://jfrog.com/help/r/add-extensions), [Infrastructure](https://jfrog.com/help/r/infrastructure-customization), [ConfigMaps](https://jfrog.com/help/r/use-configmaps-to-store-non-confidential-data), [External DB](https://jfrog.com/help/r/use-an-external-database-with-artifactory-helm-installation), [Bootstrap](https://jfrog.com/help/r/bootstraps-artifactory), [Monitoring/logging](https://jfrog.com/help/r/monitoring-and-logging-in-artifactory-helm-installation), [Nginx SSL](https://jfrog.com/help/r/install-artifactory-and-artifactory-ha-with-nginx-and-terminate-ssl-in-nginx-service-load-balancer), [readOnlyRootFilesystem](https://jfrog.com/help/r/configure-readonlyrootfilesystem-in-artifactory-containers), [HPA](https://jfrog.com/help/r/add-memory-target-trigger-to-artifactory-charts-using-hpa) |
| **Artifactory HA** | [HA storage](https://jfrog.com/help/r/artifactory-storage), [HA licenses](https://jfrog.com/help/r/add-licenses-with-artifactory-ha-helm-installation), [Scale HA](https://jfrog.com/help/r/scale-the-artifactory-ha-helm-installation-cluster), [Existing PVC](https://jfrog.com/help/r/use-an-existing-volume-claim-for-artifactory-ha-helm-installation), [Shared PVC](https://jfrog.com/help/r/use-an-existing-shared-volume-claim-with-artifactory-ha-helm-installation) |
| **Xray** | [TLS in RabbitMQ (Xray chart)](https://jfrog.com/help/r/enable-tls-in-rabbitmq-in-xray-helm-chart), [TLS in RabbitMQ (Platform chart)](https://jfrog.com/help/r/enable-tls-in-rabbitmq-for-xray-in-jfrog-platform-chart), [Disable TLS in RabbitMQ](https://jfrog.com/help/r/disable-tls-in-rabbitmq-for-xray-in-jfrog-platform-chart) |
| **Uninstall** | [Uninstall Platform](https://jfrog.com/help/r/uninstall-jfrog-platform-using-helm-chart) |

Official index: [Helm Charts for Advanced Users](https://jfrog.com/help/r/helm-charts-for-advanced-users).

---

## Doc links (canonical)

- **Install workflow:** [Install JFrog Platform using Helm Chart](https://jfrog.com/help/r/install-the-jfrog-platform-using-helm-chart)
- **Argo CD (official):** [Install JFrog Platform using Helm Chart and Argo CD](https://jfrog.com/help/r/install-jfrog-platform-using-helm-chart-argo-cd)
- **Upgrade:** [Upgrade JFrog Platform using Helm Chart](https://jfrog.com/help/r/upgrade-jfrog-platform-using-helm-chart)
- **Uninstall:** [Uninstall JFrog Platform using Helm Chart](https://jfrog.com/help/r/uninstall-jfrog-platform-using-helm-chart)
- **Troubleshooting:** [Platform Helm chart troubleshooting](https://jfrog.com/help/r/platform-helm-chart-troubleshooting)
- **Advanced:** [Helm Charts for Advanced Users](https://jfrog.com/help/r/helm-charts-for-advanced-users)
- **Charts source:** [jfrog/charts](https://github.com/jfrog/charts)

*Note: If your organization uses a different doc base URL, adjust the links accordingly.*
