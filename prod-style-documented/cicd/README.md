# Continuous Integration and Delivery

The delivery pipeline uses GitHub Actions to test the Python application, build a container image, publish it to GitHub Container Registry, and deploy the exact commit image to Kubernetes.

Workflow definition: [`.github/workflows/geoapi.yml`](../.github/workflows/geoapi.yml)

## Pipeline Flow

```text
Push to main
    ↓
Install Python dependencies
    ↓
Run pytest
    ↓
Build container image
    ↓
Push <commit-sha> and latest tags to GHCR
    ↓
Apply Kubernetes manifests
    ↓
Set Deployment image to <commit-sha>
    ↓
Wait for rollout completion
```

## Trigger Conditions

The workflow runs when:

- A change is pushed to `main` under `api/**`.
- The workflow file itself changes.
- A user starts it manually with `workflow_dispatch`.

## Jobs

| Job | Responsibility | Dependency |
|---|---|---|
| `test` | Installs Python 3.12 dependencies and runs `pytest -q` | None |
| `build-push` | Authenticates to GHCR and publishes the image | `test` |
| `deploy` | Configures kubectl, applies manifests, and updates the image | `build-push` |

## Image Strategy

The pipeline publishes two tags:

| Tag | Purpose |
|---|---|
| `ghcr.io/sinae99/geoapi:<commit-sha>` | Immutable deployment and traceability |
| `ghcr.io/sinae99/geoapi:latest` | Convenience tag for the newest successful build |

The deployment job explicitly updates Kubernetes to the commit SHA rather than relying on `latest`.

## Required GitHub Configuration

| Secret or Token | Purpose |
|---|---|
| `KUBECONFIG` | Full kubeconfig content used by the deploy job |
| `GITHUB_TOKEN` | Automatically provided token used to publish the image to GHCR |

The workflow requests `contents: read` and `packages: write` permissions.

## Deployment Resources

The deploy job applies resources in this order:

1. `api/k8s/namespace.yaml`
2. `api/k8s/secret.yaml`
3. `api/k8s/secret-ghcr.yaml`
4. `api/k8s/deployment.yaml`
5. `api/k8s/service.yaml`
6. `api/k8s/servicemonitor.yaml`

It then updates `deployment/geoapi` in the `geoapi` namespace and waits up to 120 seconds for rollout completion.

## Registry Authentication

The GitHub runner authenticates to GHCR with `GITHUB_TOKEN`. The Kubernetes nodes use the `ghcr-cred` image pull Secret referenced by the Deployment.

## Production Notes

- Rotate the registry credential currently represented by the committed pull Secret.
- Prefer creating runtime secrets through a secret manager or protected CI variables.
- Protect the `main` branch and require the test job before merge.
- Restrict the deployment kubeconfig to only the namespaces and resources required by this workflow.
