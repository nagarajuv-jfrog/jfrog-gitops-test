---
name: Bug report
about: Report a problem with manifests, scripts, or documentation
title: '[BUG] '
labels: bug
assignees: ''
---

## Environment

- **Kubernetes:** (e.g. EKS 1.28, OpenShift 4.12, minikube)
- **Argo CD version:** (e.g. 2.9.0)
- **JFrog Platform chart version:** (e.g. 11.4.0)
- **Example used:** (e.g. evaluation, production, multi-source)

## Steps to reproduce

1.
2.
3.

## Expected behavior

## Actual behavior

## Relevant output

```bash
# Argo CD Application status
kubectl get application jfrog-platform -n argocd -o yaml

# Pods
kubectl get pods -n jfrog-platform
```

(Add any error messages, sync status, or controller logs that help.)

## Additional context

(Optional: values snippets, screenshots, custom changes.)
