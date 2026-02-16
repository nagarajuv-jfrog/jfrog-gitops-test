# Expose the Platform (Ingress / Load Balancer)

After deploying the JFrog Platform via Argo CD, expose it over HTTPS using **Kubernetes Ingress** or **OpenShift Route**. Apply this after the deployment is healthy and the Nginx service is ready.

## Kubernetes (Ingress)

Use an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) (e.g. NGINX Ingress Controller) or a LoadBalancer Service. Create a TLS secret for your domain and reference it in the Ingress.

**Minimal Ingress example:** Replace `<HOST>` and `<TLS_SECRET_NAME>` with your values.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jfrog-platform
  namespace: jfrog-platform
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"       # unlimited upload size
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"   # 10 min for large artifacts
spec:
  ingressClassName: nginx   # or your controller
  tls:
    - hosts: [<HOST>]
      secretName: <TLS_SECRET_NAME>
  rules:
    - host: <HOST>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jfrog-platform-artifactory-nginx
                port:
                  number: 80
```

**Note:** The `proxy-body-size: "0"` annotation is important for Artifactory — without it, large artifact uploads can fail with `413 Request Entity Too Large`.

## OpenShift (Route)

Use an [OpenShift Route](https://docs.openshift.com/container-platform/latest/networking/routes/route-configuration.html) with TLS.

**Minimal Route example:** Replace `<HOST>` with your domain.

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: jfrog-platform
  namespace: jfrog-platform
spec:
  host: <HOST>
  to:
    kind: Service
    name: jfrog-platform-artifactory-nginx
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

For passthrough TLS or re-encrypt termination, see OpenShift documentation.

## Verify external access

```bash
# Verify the resource
kubectl get ingress -n jfrog-platform   # Kubernetes
kubectl get route -n jfrog-platform      # OpenShift

# Test connectivity
curl -k https://<HOST>/artifactory/api/system/ping
# Expected: OK
```

After configuring external access, set the **Artifactory Base URL** in Administration → General Configuration to match your Ingress or Route hostname. This is required for Docker registries, smart remotes, and access tokens.

For advanced Ingress, Nginx, and TLS options, see the official [Helm Charts for Advanced Users](https://jfrog.com/help/r/helm-charts-for-advanced-users) and [Establish TLS](https://jfrog.com/help/r/establish-tls-in-artifactory-and-jfrog-platform).
