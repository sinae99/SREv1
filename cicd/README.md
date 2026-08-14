# cicd : GitHub Actions + Argo CD

```text
git push
  -> CI: test + build + push image + update Git
  -> CD: Argo CD syncs Git to Kubernetes
```

| Part | Tool | Responsibility |
|------|------|----------------|
| [`ci/`](ci/README.md) | GitHub Actions + GHCR | Test, build, publish image, update desired image in Git |
| [`cd/`](cd/README.md) | Argo CD | Deploy Git manifests to Kubernetes and verify health |

GitHub Actions does **not** have cluster access and does **not** run `kubectl`.
Argo CD owns the deployment phase.

## flow

```text
source push
  -> pytest
  -> docker build
  -> ghcr.io/sinae99/geoapi:<sha>
  -> update api/k8s/deployment.yaml
  -> Argo CD detects Git change
  -> Kubernetes rollout
```

## files

| Path | Purpose |
|------|---------|
| `ci/README.md` | CI flow and GitHub Actions details |
| `cd/README.md` | Argo CD install, apply, deploy, and verification steps |
| `cd/app-project.yaml` | Restrict Argo CD source and destination |
| `cd/application.yaml` | Deploy `main:api/k8s` to the `geoapi` namespace |
