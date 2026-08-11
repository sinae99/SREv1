# api : IP geolocation (Flask)

Stack: Flask + psycopg + prometheus-client.

---

## Endpoints

| Path | Description |
|------|-------------|
| `GET /iploc?ip=8.8.8.8` | Lookup (Postgres cache, then ip-api.com) |
| `GET /health` | `{"status":"ok"}` |
| `GET /metrics` | Prometheus metrics (see [`metrics/README.md`](metrics/README.md)) |

---

## Deploy

### 1. Build and push image to GHCR

```bash
cd /path/to/arvan

docker build -t ghcr.io/sinae99/geoapi:latest ./api
echo "$GITHUB_TOKEN" | docker login ghcr.io -u sinae99 --password-stdin
docker push ghcr.io/sinae99/geoapi:latest
```

If the GHCR package is **private**, create a pull secret and add `imagePullSecrets` to [`k8s/deployment.yaml`](k8s/deployment.yaml):

```bash
kubectl -n geoapi create secret docker-registry ghcr-cred \
  --docker-server=ghcr.io \
  --docker-username=sinae99 \
  --docker-password="$GITHUB_TOKEN"
```

Then under `spec.template.spec` in the Deployment:

```yaml
imagePullSecrets:
  - name: ghcr-cred
```

### 2. Create DB secret (from CNPG)

```bash
bash api/k8s/create-secret.sh
```

This reads `sina-db-app` in namespace `postgres` and writes Secret `geoapi-db` with `DATABASE_URL` pointing at:

`sina-db-rw.postgres.svc.cluster.local:5432/geoapi`

### 3. Apply manifests

```bash
kubectl apply -f api/k8s/namespace.yaml
kubectl apply -f api/k8s/deployment.yaml
kubectl apply -f api/k8s/service.yaml
kubectl apply -f api/k8s/servicemonitor.yaml
```

### 4. Verify

```bash
kubectl -n geoapi get pods,svc,servicemonitor
kubectl -n geoapi logs deploy/geoapi

kubectl -n geoapi port-forward svc/geoapi 8080:80
curl "http://127.0.0.1:8080/iploc?ip=8.8.8.8"
curl "http://127.0.0.1:8080/health"
curl "http://127.0.0.1:8080/metrics"
``` 

---

## Metrics

→ [`metrics/README.md`](metrics/README.md)

---

## Layout

| File | Purpose |
|------|---------|
| `app.py` | Flask app + metrics |
| `Dockerfile` | Container image |
| `requirements.txt` | Deps |
| `test_app.py` | Unit tests |
| `metrics/README.md` | Metrics + Grafana notes |
| `k8s/namespace.yaml` | Namespace `geoapi` |
| `k8s/deployment.yaml` | 1 replica, env from Secret |
| `k8s/service.yaml` | ClusterIP `:80` → pod `:8000` |
| `k8s/servicemonitor.yaml` | Prometheus scrape |
| `k8s/create-secret.sh` | Secret `geoapi-db` from CNPG |

---

## Config

| Env | Source |
|-----|--------|
| `DATABASE_URL` | Secret `geoapi-db` (created by `create-secret.sh`) |

---

## Tests

```bash
cd api
pip install -r requirements.txt
pytest -q
```

---
