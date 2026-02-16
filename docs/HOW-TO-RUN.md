# How to Run This (Step-by-Step)

Two ways to run the JFrog Platform with this repo:

- **Path A: Local** — Evaluation setup on your Mac (Rancher Desktop or kind). No external DB; good for trying it out.
- **Path B: AWS EKS** — Production setup on EKS with RDS and secrets.

---

# Path A: Local run (evaluation)

Use this to try the platform locally with minimal setup (bundled PostgreSQL, no real DB).

## Prerequisites

- **Kubernetes** — Rancher Desktop (Mac) with cluster running, **or** [kind](https://kind.sigs.k8s.io/) and Docker.
- **kubectl** — In your PATH and pointing at your cluster.
- **yq** — For installing Argo CD without the ApplicationSet CRD. Install: `brew install yq`

## Step 1: Clone the repo

```bash
cd ~/Documents   # or wherever you keep projects
git clone https://github.com/<YOUR_ORG>/jfrog-gitops-test.git
cd jfrog-gitops-test
```

(If you haven’t forked yet, clone the original repo; you can still run the evaluation example.)

## Step 2: Point kubectl at your cluster

**Rancher Desktop:** Ensure the cluster is started; Rancher Desktop sets `kubectl` for you.

**kind:**

```bash
kind create cluster
```

Then check:

```bash
kubectl cluster-info
kubectl get nodes
```

## Step 3: Install Argo CD (without ApplicationSet CRD)

Run these in order:

```bash
kubectl create namespace argocd
```

```bash
curl -fsSL -o install.yaml "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
```

```bash
yq eval-all 'select(.kind != "CustomResourceDefinition" or .metadata.name != "applicationsets.argoproj.io")' install.yaml > install-filtered.yaml
```

```bash
kubectl apply -n argocd -f install-filtered.yaml
```

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

(Or use the script: `SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh` if `yq` is installed.)

## Step 4: Deploy the evaluation Application

```bash
kubectl apply -f examples/evaluation/argocd-app.yaml
```

## Step 5: Watch until Synced

```bash
kubectl get application jfrog-platform -n argocd -w
```

Wait until **SYNC STATUS** shows **Synced** (can take 1–2 minutes). Press **Ctrl+C** to stop watching.

## Step 6: Watch pods (optional)

In another terminal:

```bash
kubectl get pods -n jfrog-platform -w
```

Artifactory may take 3–5 minutes to become **Ready**. Press **Ctrl+C** when done.

## Step 7: Verify the platform

```bash
kubectl port-forward svc/jfrog-platform-artifactory-nginx -n jfrog-platform 8082:80
```

In a browser or another terminal:

```bash
curl http://localhost:8082/artifactory/api/system/ping
```

You should see: **OK**.

## Step 8: Argo CD UI (optional)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

- Open **https://localhost:8080** in a browser (accept the TLS warning).
- Username: **admin**
- Password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

---

**Clean up (local):**

```bash
kubectl delete application jfrog-platform -n argocd
kubectl delete namespace jfrog-platform
# Optional: kubectl delete namespace argocd
# If using kind: kind delete cluster
```

---

# Path B: Run on AWS EKS (production)

Use this for a production-style deployment on EKS with RDS and secrets.

## Prerequisites

- **AWS CLI** — Configured (`aws configure` or env vars).
- **EKS cluster** — Already created (Console, Terraform, eksctl, etc.).
- **kubectl** — 1.26+.
- **yq** — `brew install yq` (for Argo CD filtered install).

## Step 1: Configure kubectl for EKS

Replace `<region>` and `<cluster-name>` with your EKS cluster details:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl cluster-info
kubectl get nodes
```

## Step 2: Clone (or fork and clone) the repo

```bash
git clone https://github.com/<YOUR_ORG>/jfrog-gitops-test.git
cd jfrog-gitops-test
```

## Step 3: Install Argo CD on EKS (filtered install)

```bash
kubectl create namespace argocd
curl -fsSL -o install.yaml "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
yq eval-all 'select(.kind != "CustomResourceDefinition" or .metadata.name != "applicationsets.argoproj.io")' install.yaml > install-filtered.yaml
kubectl apply -n argocd -f install-filtered.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

Or: `SKIP_APPLICATIONSET_CRD=1 ./scripts/setup-argocd.sh`

## Step 4: Create namespace and secrets

```bash
kubectl create namespace jfrog-platform
```

Set your real values (replace placeholders), then run the script:

```bash
export ARTIFACTORY_DB_USER="artifactory"
export ARTIFACTORY_DB_PASSWORD="<your-secure-password>"
export XRAY_DB_USER="xray"
export XRAY_DB_PASSWORD="<your-secure-password>"
export MASTER_KEY="<from-jfrog-docs>"
export JOIN_KEY="<from-jfrog-docs>"

./scripts/create-secrets.sh
```

(Optional) Pre-create TLS secret:

```bash
./scripts/create-tls-secret.sh <your-domain>
```

## Step 5: Use the EKS example and set your Git repo

```bash
cp examples/eks/argocd-app.yaml .
cp examples/eks/customvalues.yaml .
```

Edit **argocd-app.yaml** and replace `<YOUR_ORG>` and `<YOUR_REPO>` with your Git org and repo (so Argo CD pulls values from your fork):

```yaml
- repoURL: https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
  targetRevision: main
  ref: values
```

Edit **customvalues.yaml** and set at least:

- **Artifactory DB URL** — Replace `<RDS_ARTIFACTORY_ENDPOINT>` with your RDS endpoint, e.g. `my-db.xxxx.us-east-1.rds.amazonaws.com`.
- **Secret names** — Must match what you created (e.g. `artifactory-db-secret`, `xray-db-secret`, `my-platform-keys`).
- **TLS** — If you created a TLS secret, ensure `artifactory.nginx.tlsSecretName` matches (e.g. `jfrog-platform-tls`).

If you use the same repo for both chart and values (single repo), the Application’s second source can point to your fork; ensure `customvalues.yaml` is in the repo root or the path in `valueFiles` exists.

## Step 6: Deploy the Application

From the repo root (where `argocd-app.yaml` is):

```bash
kubectl apply -f argocd-app.yaml
```

## Step 7: Watch until Synced

```bash
kubectl get application jfrog-platform -n argocd -w
```

Wait until **SYNC STATUS** is **Synced**. Press **Ctrl+C** to stop.

## Step 8: Watch pods

In another terminal:

```bash
kubectl get pods -n jfrog-platform -w
```

Wait for Artifactory (and Xray, if enabled) to become **Ready**.

## Step 9: Verify

```bash
kubectl port-forward svc/jfrog-platform-artifactory-nginx -n jfrog-platform 8082:80
curl http://localhost:8082/artifactory/api/system/ping
```

Expected: **OK**.

## Step 10: Expose with ALB (optional)

See [INGRESS-ROUTE.md](INGRESS-ROUTE.md#aws-alb-eks) for an Ingress example using the AWS Load Balancer Controller.

---

**Clean up (EKS):**

```bash
kubectl delete application jfrog-platform -n argocd
kubectl delete namespace jfrog-platform
# RDS and other external resources are not deleted; remove them separately if needed.
```

---

# Quick reference

| Step              | Local (evaluation)              | EKS (production)                          |
|-------------------|----------------------------------|-------------------------------------------|
| Cluster           | Rancher Desktop or kind          | `aws eks update-kubeconfig`               |
| Argo CD           | Filtered install (yq)            | Filtered install (yq)                     |
| App manifest       | `examples/evaluation/argocd-app.yaml` | `examples/eks/` → copy and edit repo URL |
| Values             | Inline in evaluation app         | Edit `customvalues.yaml` (RDS, secrets)   |
| Secrets            | None (bundled DB)                | `./scripts/create-secrets.sh`            |
| Deploy             | `kubectl apply -f examples/evaluation/argocd-app.yaml` | `kubectl apply -f argocd-app.yaml` |
| Verify             | `curl http://localhost:8082/artifactory/api/system/ping` | Same (after port-forward)        |

For more detail, see [TESTING.md](TESTING.md) (local) and [DEPLOY-EKS.md](DEPLOY-EKS.md) (EKS).
