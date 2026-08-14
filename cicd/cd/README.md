# cd : Argo CD

GeoAPI deployment phase.

```text
Git desired state -> Argo CD -> Kubernetes API -> GeoAPI rollout
```

GitHub Actions only tests, builds, publishes the image, and records the image
SHA in Git.

| Component | Role |
|-----------|------|
| GitHub Actions | Produce `ghcr.io/sinae99/geoapi:<sha>` and update Git |
| Git repository | Store the desired Kubernetes state |
| Argo CD | Compare Git with the cluster and apply changes |
| Kubernetes | Create ReplicaSets, Pods, Services, and Secrets |

---



## 1. install Argo CD

Create the ns:

```bash
kubectl create namespace argocd
```

Install Argo CD:

```bash
kubectl apply --server-side --force-conflicts \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---


## 3. access Argo CD

Print the initial admin password:

```bash
argocd admin initial-password -n argocd
```

Forward the API server and UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```


---

## 4. repo access

The Application reads:

```text
https://github.com/sinae99/SREv1.git
```

Verify repository access:

```bash
argocd repo list
```

Expect the repository connection status to be `Successful`.

---

## 5. review the Argo CD project

[`app-project.yaml`](app-project.yaml) allows:

- source repository `https://github.com/sinae99/SREv1.git`;
- in-cluster Kubernetes destination;
- destination namespace `geoapi`;
- the cluster-scoped `Namespace` resource;
- namespaced GeoAPI resources.


Apply:

```bash
kubectl apply -f cicd/cd/app-project.yaml
```

Verify:

```bash
kubectl get appproject geoapi -n argocd -o yaml
```

---

## 6. review the Argo CD application

[`application.yaml`](application.yaml) watches:

| Setting | Value |
|---------|-------|
| Repository | `https://github.com/sinae99/SREv1.git` |
| Branch | `main` |
| Path | `api/k8s` |
| Cluster | `https://kubernetes.default.svc` |
| Namespace | `geoapi` |
| Auto sync | Enabled |
| Prune | Enabled |
| Self-heal | Enabled |

Apply:

```bash
kubectl apply -f cicd/cd/application.yaml
```

---

## 7. verify the Argo CD application

Check the Application resource:

```bash
kubectl get application geoapi -n argocd
kubectl describe application geoapi -n argocd
```

Check through the Argo CD CLI:

```bash
argocd app get geoapi
argocd app resources geoapi
argocd app history geoapi
```

Expect:

- Sync Status: `Synced`;
- Health Status: `Healthy`;
- Revision: a commit from `main`;
- resources in the `geoapi` namespace.

If the first reconciliation has not started, refresh the Application:

```bash
argocd app get geoapi --refresh
```

Automated synchronization performs the sync after Argo CD detects the Git
state. Do not add `argocd app sync` to GitHub Actions.

---

## 8. verify Kubernetes resources

```bash
kubectl get namespace geoapi
kubectl get deployment,pods,svc,secrets -n geoapi
kubectl get servicemonitor -n geoapi
```

Wait for the application rollout:

```bash
kubectl rollout status deployment/geoapi \
  -n geoapi \
  --timeout=180s
```

Check the deployed image:

```bash
kubectl get deployment geoapi \
  -n geoapi \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Expect an immutable image similar to:

```text
ghcr.io/sinae99/geoapi:<git-commit-sha>
```

Check application health:

```bash
kubectl port-forward svc/geoapi -n geoapi 8000:80
```

From another terminal:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/metrics
```

---

## 10. verify a complete deployment

Change an application file such as `api/app.py`, then commit and push it to
`main`.

Verify the CI workflow in GitHub Actions:

1. `test` passes.
2. `build-push` publishes `ghcr.io/sinae99/geoapi:<sha>`.
3. `update-manifest` commits the same SHA to `api/k8s/deployment.yaml`.
4. No GitHub Actions job contacts Kubernetes.

Pull the GitHub Actions manifest commit locally:

```bash
git pull
git log -1 --oneline -- api/k8s/deployment.yaml
grep 'image:' api/k8s/deployment.yaml
```

Watch Argo CD and Kubernetes:

```bash
argocd app get geoapi --refresh
kubectl get pods -n geoapi -w
```

Verify the final revision and image:

```bash
argocd app history geoapi
kubectl get deployment geoapi \
  -n geoapi \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The image SHA in Kubernetes must match the image SHA committed to Git.

---

## 11. verify self-heal

This optional test creates temporary live drift by changing the replica count:

```bash
kubectl scale deployment geoapi -n geoapi --replicas=2
kubectl get deployment geoapi -n geoapi -w
```

The manifest declares one replica. Argo CD should detect the drift and restore
the Deployment to one replica.

Verify:

```bash
kubectl get deployment geoapi \
  -n geoapi \
  -o jsonpath='{.spec.replicas}{"\n"}'
```

Expect:

```text
1
```

---

## 12. rollback

Find the manifest deployment commits:

```bash
git log --oneline -- api/k8s/deployment.yaml
```

Revert the unwanted image update and push the revert to `main`:

```bash
git revert <manifest-commit>
git push origin main
```

Argo CD detects the reverted desired state and Kubernetes rolls out the previous
image.

Verify:

```bash
argocd app get geoapi --refresh
kubectl rollout status deployment/geoapi -n geoapi
```

Do not use `kubectl set image` for a permanent rollback. Argo CD self-heal will
restore the image declared in Git.

---

## 13. troubleshooting

Application status and diff:

```bash
argocd app get geoapi --refresh
argocd app diff geoapi
kubectl describe application geoapi -n argocd
```

Argo CD controller and repository logs:

```bash
kubectl logs -n argocd statefulset/argocd-application-controller
kubectl logs -n argocd deployment/argocd-repo-server
```

GeoAPI rollout and events:

```bash
kubectl describe deployment geoapi -n geoapi
kubectl get events -n geoapi --sort-by=.lastTimestamp
kubectl logs -n geoapi deployment/geoapi
```

Common checks:

| Problem | Check |
|---------|-------|
| Repository connection fails | `argocd repo list` and repository credentials |
| Application is OutOfSync | `argocd app diff geoapi` |
| Image cannot be pulled | `ghcr-cred` and GHCR package access |
| `ServiceMonitor` fails | Prometheus Operator CRDs are installed |
| Deployment does not update | Image SHA changed in `api/k8s/deployment.yaml` |
| Workflow cannot push manifest | Repository workflow permissions or branch protection |

---

## 14. security

After confirming the new pipeline works, delete the old `KUBECONFIG` secret
from the GitHub repository. GitHub Actions no longer needs cluster credentials.

The challenge repository currently includes application and GHCR credentials in
`api/k8s/secret.yaml` and `api/k8s/secret-ghcr.yaml`. Rotate these credentials
before using this setup outside the challenge environment.

For production, manage secrets with an encrypted or external secret system
instead of committing usable credentials to Git.

---

## files

| File | Purpose |
|------|---------|
| `app-project.yaml` | Restrict the repository, cluster, namespace, and resource types |
| `application.yaml` | Watch `main:api/k8s` and automatically deploy GeoAPI |
| `README.md` | Install, apply, deploy, verify, self-heal, rollback, and troubleshoot |
