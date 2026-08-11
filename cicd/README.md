# cicd : GitHub Actions → GHCR → cluster

```
git push → pytest → docker build → ghcr.io/sinae99/geoapi → kubectl apply
```

Workflow: [`.github/workflows/geoapi.yml`](../.github/workflows/geoapi.yml)

## flow

| Step | What |
|------|------|
| test | `pytest` in `api/` |
| build-push | `ghcr.io/sinae99/geoapi:<sha>` + `:latest` |
| deploy | apply `api/k8s/` → set image to `<sha>` |

Triggers: `push` to `main` (`api/**`, workflow file) or `workflow_dispatch`.

## Secrets

| Secret | Source |
|--------|--------|
| `KUBECONFIG` | Contents of [`kubernetes/kubeconfig`](../kubernetes/kubeconfig) |
| `GITHUB_TOKEN` | Automatic (GHCR push) |


## Private GHCR

Cluster pull uses [`api/k8s/secret-ghcr.yaml`](../api/k8s/secret-ghcr.yaml) (`ghcr-cred`).


## Deploy manifests

```bash
kubectl apply -f api/k8s/namespace.yaml
kubectl apply -f api/k8s/secret.yaml
kubectl apply -f api/k8s/secret-ghcr.yaml
kubectl apply -f api/k8s/deployment.yaml
kubectl apply -f api/k8s/service.yaml
kubectl apply -f api/k8s/servicemonitor.yaml
kubectl -n geoapi set image deploy/geoapi geoapi=ghcr.io/sinae99/geoapi:<sha>
```

