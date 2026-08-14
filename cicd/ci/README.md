# ci : GitHub Actions + GHCR

Workflow: [`.github/workflows/geoapi.yml`](../../.github/workflows/geoapi.yml)

```text
git push -> pytest -> docker build -> GHCR -> update image tag in Git
```

GitHub Actions performs CI only. Deployment is handled by
[`cicd/cd`](../cd/README.md) with Argo CD.

## flow

| Job | What |
|-----|------|
| `test` | Install dependencies and run `pytest` in `api/` |
| `build-push` | Push `ghcr.io/sinae99/geoapi:<sha>` and `:latest` |
| `update-manifest` | Commit the immutable image SHA to `api/k8s/deployment.yaml` |

The `update-manifest` job updates the desired state in Git. It does not connect
to Kubernetes and does not perform the deployment.

## permissions

| Permission | Job | Purpose |
|------------|-----|---------|
| `contents: read` | `test`, `build-push` | Checkout source code |
| `packages: write` | `build-push` | Push the image to GHCR |
| `contents: write` | `update-manifest` | Commit the image SHA to `main` |

`GITHUB_TOKEN` is provided automatically by GitHub Actions.

The workflow does not need:

- `KUBECONFIG`;
- a Kubernetes service account token;
- an Argo CD token;
- `kubectl`.

Delete the old `KUBECONFIG` repository secret after this workflow is active.

## trigger paths

CI runs when one of these files changes on `main`:

- `api/app.py`;
- `api/test_app.py`;
- `api/requirements.txt`;
- `api/Dockerfile`;
- `.github/workflows/geoapi.yml`.

A manifest-only commit does not rebuild the application image. Argo CD detects
that Git change and handles it through the CD flow.

## verify

Open the `geoapi` workflow in GitHub Actions and confirm:

1. `test` succeeds.
2. `build-push` publishes the SHA image.
3. `update-manifest` changes `api/k8s/deployment.yaml`.
4. No job runs `kubectl` or reads a kubeconfig.

Continue with the deployment runbook:

[`cicd/cd/README.md`](../cd/README.md)
