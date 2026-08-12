# GeoAPI Application

The application is a small Flask service that resolves an IP address to its country, stores successful results in PostgreSQL, and uses the database as a cache for future requests. It exposes health and Prometheus endpoints for Kubernetes operations and monitoring.

## Features

- IP-to-country lookup through `ip-api.com`.
- PostgreSQL-backed response caching.
- Idempotent database schema creation.
- Prometheus request and cache-size metrics.
- Kubernetes liveness and readiness probes.
- Resource requests and limits.
- Unit tests for success, cache, validation, and failure paths.

## Technology Stack

| Layer | Technology |
|---|---|
| Web service | Python 3.12 and Flask |
| Production server | Gunicorn |
| Database driver | Psycopg 3 |
| Database | PostgreSQL managed by CloudNativePG |
| Metrics | Prometheus Python client |
| Packaging | Docker |
| Orchestration | Kubernetes |

## Request Flow

```text
Client request
    ↓
GET /iploc?ip=<address>
    ↓
Check PostgreSQL cache
    ├── cache hit  → return stored country
    └── cache miss → query ip-api.com → store result → return country
```

## API Endpoints

| Method and Path | Description | Typical Status |
|---|---|---|
| `GET /iploc?ip=8.8.8.8` | Resolves an IP address and caches the result | `200` |
| `GET /iploc` | Rejects a request without the `ip` query parameter | `400` |
| `GET /health` | Reports that the process is available | `200` |
| `GET /metrics` | Exposes Prometheus text-format metrics | `200` |

Lookup or database errors are returned as `502` responses.

## Metrics

| Metric | Type | Purpose |
|---|---|---|
| `iploc_requests_total` | Counter | Counts requests received by `/iploc` |
| `iploc_cached_ips` | Gauge | Reports the number of cached IP records in PostgreSQL |

See [`metrics/README.md`](metrics/README.md) for query and dashboard notes.

## Directory Structure

```text
api/
├── app.py                  # Flask application, database cache, and metrics
├── Dockerfile              # Production container image
├── requirements.txt        # Pinned runtime and test dependencies
├── test_app.py             # Unit tests
├── test-api.md             # Recorded API verification steps
├── metrics/README.md       # Prometheus and Grafana notes
└── k8s/
    ├── namespace.yaml      # geoapi namespace
    ├── secret.yaml         # PostgreSQL connection string
    ├── secret-ghcr.yaml    # GHCR image pull credentials
    ├── deployment.yaml     # Workload, probes, resources, and environment
    ├── service.yaml        # Internal ClusterIP service
    └── servicemonitor.yaml # Prometheus discovery configuration
```

## Runtime Configuration

The application requires one environment variable:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URI used for schema creation, reads, and writes |

The Kubernetes Deployment reads this value from the `geoapi-db` Secret.

## Container Image

The image uses `python:3.12-slim`, installs the pinned dependencies, copies the application, and starts Gunicorn on port `8000`.

```bash
docker build -t geoapi:local .
```

## Unit Tests

```bash
cd api
pip install -r requirements.txt
pytest -q
```

The test suite mocks the database and external API, so it verifies application behavior without requiring the live cluster.

## Kubernetes Deployment

Apply resources in dependency order:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/secret-ghcr.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/servicemonitor.yaml
```

Verify the workload:

```bash
kubectl get pods,svc -n geoapi
kubectl rollout status deployment/geoapi -n geoapi
```

## Production Notes

- Replace committed secret material with externally managed Kubernetes Secrets before publishing the project.
- The Deployment uses `Always` image pulls and the CI pipeline pins each rollout to a commit SHA.
- The application Service is intentionally internal (`ClusterIP`). External access requires an ingress, gateway, or port-forward.
