# Deploy JFrog Platform on AWS EKS (Production-Grade)

Step-by-step instructions to deploy the JFrog Platform on **Amazon EKS** using Argo CD and this GitOps repo. The flow mirrors [TESTING.md](TESTING.md): prepare cluster → install Argo CD → create secrets → deploy Application → verify.

---

## Prerequisites

| Requirement | Notes |
|:---|:---|
| **AWS CLI** | Configured with credentials that can create/access EKS clusters |
| **kubectl** | 1.26+ |
| **EKS cluster** | 1.26+; created via AWS Console, Terraform, eksctl, or CloudFormation |
| **Helm** (optional) | For local `helm template` checks |
| **yq** (optional) | For installing Argo CD without the ApplicationSet CRD (avoids 262144-byte annotation limit on many clusters) |

---

## 1. Configure kubectl for your EKS cluster

Point `kubectl` at your EKS cluster:

```bash
# Replace <region> and <cluster-name> with your EKS cluster details
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Verify
kubectl cluster-info
kubectl get nodes
```

---

## 2. Install Argo CD on EKS

Many clusters (including EKS) hit the **262144-byte annotation limit** on the ApplicationSet CRD. Install Argo CD **without** that CRD so the install succeeds. You will still use normal `Application` resources (this repo does not use ApplicationSet).

**Option A: Filtered install (recommended)**

Requires [yq](https://github.com/mikefarah/yq) (`brew install yq` on macOS):

```bash
kubectl create namespace argocd
curl -fsSL -o install.yaml "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
yq eval-all 'select(.kind != "CustomResourceDefinition" or .metadata.name != "applicationsets.argoproj.io")' install.yaml > install-filtered.yaml
kubectl apply -n argocd -f install-filtered.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

**Option B: Use the setup script with filter**

```bash
SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh
```

**Option C: Full install (only if your cluster accepts the ApplicationSet CRD)**

```bash
./scripts/setup-argocd.sh
```

If you see `metadata.annotations: Too long: may not be more than 262144 bytes`, use Option A or B.

---

## 3. Create namespace and secrets

Production and EKS examples use **external databases** and **Kubernetes secrets** for credentials. Never commit real credentials to Git.

```bash
# Create the namespace
kubectl create namespace jfrog-platform

# Create secrets (set env vars or you will get placeholders)
export ARTIFACTORY_DB_USER="artifactory"
export ARTIFACTORY_DB_PASSWORD="<secure-password>"
export XRAY_DB_USER="xray"
export XRAY_DB_PASSWORD="<secure-password>"
export MASTER_KEY="<from-jfrog-docs>"
export JOIN_KEY="<from-jfrog-docs>"

./scripts/create-secrets.sh
```

For RDS endpoints and secret keys, see [scripts/create-secrets.sh](../scripts/create-secrets.sh) and the [JFrog Platform Administration](https://jfrog.com/help/r/jfrog-platform-administration-documentation/) documentation.

**Optional:** Pre-create a stable TLS secret so the chart does not regenerate it (avoids Argo CD drift):

```bash
./scripts/create-tls-secret.sh <your-domain>
```

---

## 4. Fork, clone, and choose your example

1. **Fork** this repo and **clone** your fork.
2. Use the **EKS** or **production** example:

| Example | Use case |
|:---|:---|
| [examples/eks/](../examples/eks/) | Production-grade EKS: RDS, secrets, ALB-ready values, full ignoreDifferences |
| [examples/production/](../examples/production/) | Production with external DB; same pattern, not EKS-specific |

3. Copy the example into your repo root (or use the example path when applying):

```bash
# If using EKS example and deploying from repo root
cp examples/eks/argocd-app.yaml .
cp examples/eks/customvalues.yaml .
```

4. **Edit `argocd-app.yaml`**  
   Replace `<YOUR_ORG>` and `<YOUR_REPO>` with your Git org and repo so Argo CD pulls values from your fork:

   ```yaml
   - repoURL: https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
     targetRevision: main
     ref: values
   ```

5. **Edit `customvalues.yaml`**  
   Set at least:
   - **Database URLs** — Artifactory and Xray RDS endpoints (e.g. `jdbc:postgresql://<rds-endpoint>:5432/artifactory`).
   - **Secret names** — Must match the secrets you created (e.g. `artifactory-db-secret`, `xray-db-secret`, `my-platform-keys`).
   - **TLS** — `artifactory.nginx.tlsSecretName` if you created a TLS secret.

   See [examples/eks/customvalues.yaml](../examples/eks/customvalues.yaml) for placeholders and comments.

---

## 5. Deploy the Application

From the repo root (where your `argocd-app.yaml` lives):

```bash
kubectl apply -f argocd-app.yaml
```

If you did not copy to root:

```bash
kubectl apply -f examples/eks/argocd-app.yaml
```

(Ensure the Application’s `valueFiles` point to the correct path; the EKS example uses `$values/customvalues.yaml` from the Git ref.)

---

## 6. Verify

**Sync status**

```bash
kubectl get application jfrog-platform -n argocd -w
```

Wait until `SYNC STATUS` is **Synced**.

**Pods**

```bash
kubectl get pods -n jfrog-platform -w
```

Artifactory can take 3–5 minutes to become Ready on first boot.

**Quick API check (port-forward)**

```bash
kubectl port-forward svc/jfrog-platform-artifactory-nginx -n jfrog-platform 8082:80
curl http://localhost:8082/artifactory/api/system/ping
# Expected: OK
```

**Argo CD UI**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (username: admin)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 7. Expose the platform (AWS ALB)

To expose the platform over HTTPS using an **Application Load Balancer**, use the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) and an Ingress with the `alb` ingress class. See [INGRESS-ROUTE.md](INGRESS-ROUTE.md#aws-alb-eks) for an example.

---

## Summary checklist

- [ ] EKS cluster created and `kubectl` configured (`aws eks update-kubeconfig`)
- [ ] Argo CD installed (filtered install if you hit the 262144-byte CRD limit)
- [ ] Namespace `jfrog-platform` and secrets created
- [ ] Repo forked; `argocd-app.yaml` and `customvalues.yaml` updated (repo URL, DB URLs, secret names)
- [ ] Application applied and Synced
- [ ] Pods Running/Ready; optional Ingress/ALB for external access

---

## Cleanup

```bash
kubectl delete application jfrog-platform -n argocd
kubectl delete namespace jfrog-platform
# Optional: kubectl delete namespace argocd
```

PVCs and external resources (RDS, S3) are not deleted. See [UNINSTALL.md](UNINSTALL.md) and the official [Uninstall JFrog Platform](https://jfrog.com/help/r/uninstall-jfrog-platform/) documentation.
