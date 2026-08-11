# cicd : GitHub Actions

```
git push
  → test (pytest)
  → build Docker image
  → push GHCR (ghcr.io/sinae99/geoapi)
  → kubectl apply manifests
  → cluster (Arvan K8s)
```

Workflow file: [`.github/workflows/geoapi.yml`](../.github/workflows/geoapi.yml)

---

## Flow

| Step | What |
|------|------|
| 1. test | `pytest` in `api/` |
| 2. build-push | `docker build` → `ghcr.io/sinae99/geoapi:<sha>` + `:latest` |
| 3. deploy | kubeconfig from secret → apply `api/k8s/` (incl. `secret.yaml`) → set image to `<sha>` |

Triggers:

- `push` to `main` when `api/**` or the workflow file changes
- `workflow_dispatch` (manual)

---

## Secrets

| Secret | Source |
|--------|--------|
| `KUBECONFIG` | Full contents of [`kubernetes/kubeconfig`](../kubernetes/kubeconfig) |
| `GITHUB_TOKEN` | Automatic (GHCR push) |

### KUBECONFIG 


1. Open `kubernetes/kubeconfig` on your machine (gitignored)
2. GitHub → repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
3. Name: `KUBECONFIG`
4. Value: paste the entire file

GitHub-hosted runners must reach the API server (`vm1` public IP `:6443`).

---

## GHCR package visibility

After the first successful push, set the `geoapi` package to **Public** (GitHub → Packages), so cluster nodes can pull without an `imagePullSecret`.

---

## What deploy applies

```bash
kubectl apply -f api/k8s/namespace.yaml
kubectl apply -f api/k8s/secret.yaml
kubectl apply -f api/k8s/deployment.yaml
kubectl apply -f api/k8s/service.yaml
kubectl apply -f api/k8s/servicemonitor.yaml
kubectl -n geoapi set image deploy/geoapi geoapi=ghcr.io/sinae99/geoapi:<sha>
```
---

## Files

| Path | Role |
|------|------|
| [`.github/workflows/geoapi.yml`](../.github/workflows/geoapi.yml) | Pipeline |
| This README | Flow + secrets |
| [`api/k8s/`](../api/k8s/) | Deploy manifests |
| [`kubernetes/kubeconfig`](../kubernetes/kubeconfig) | Local source for the `KUBECONFIG` secret |
