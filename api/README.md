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

Use a **PAT** (`write:packages` / `read:packages`). CI uses `GITHUB_TOKEN` automatically.

### 2. Apply manifests

```bash
kubectl apply -f api/k8s/namespace.yaml
kubectl apply -f api/k8s/secret.yaml
kubectl apply -f api/k8s/secret-ghcr.yaml
kubectl apply -f api/k8s/deployment.yaml
kubectl apply -f api/k8s/service.yaml
kubectl apply -f api/k8s/servicemonitor.yaml
```

| Manifest | Role |
|----------|------|
| [`k8s/secret.yaml`](k8s/secret.yaml) | `geoapi-db` → `DATABASE_URL` (Postgres) |
| [`k8s/secret-ghcr.yaml`](k8s/secret-ghcr.yaml) | `ghcr-cred` → pull private image from GHCR |

Deployment uses:

- `imagePullSecrets: [{ name: ghcr-cred }]` — auth for private `ghcr.io/sinae99/geoapi`
- `imagePullPolicy: Always` — always re-pull (needed when tagging `:latest` or after each CI sha)

### 3. Verify

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
| `k8s/deployment.yaml` | 1 replica; `imagePullSecrets: ghcr-cred`; `imagePullPolicy: Always` |
| `k8s/service.yaml` | ClusterIP `:80` → pod `:8000` |
| `k8s/servicemonitor.yaml` | Prometheus scrape |
| `k8s/secret.yaml` | Secret `geoapi-db` (`DATABASE_URL`) |
| `k8s/secret-ghcr.yaml` | Secret `ghcr-cred` (pull from private GHCR) |

---

## Config

| Env | Source |
|-----|--------|
| `DATABASE_URL` | Secret `geoapi-db` from [`k8s/secret.yaml`](k8s/secret.yaml) |

---

## Tests

```bash
cd api
pip install -r requirements.txt
pytest -q
```

---
