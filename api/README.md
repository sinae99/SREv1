# api : IP geolocation (Flask)

Stack: Flask + psycopg + prometheus-client.

## Endpoints

| Path | Description |
|------|-------------|
| `GET /iploc?ip=8.8.8.8` | Lookup (Postgres cache, then ip-api.com) |
| `GET /health` | `{"status":"ok"}` |
| `GET /metrics` | see [`metrics/README.md`](metrics/README.md) |

## Config

| Env | Source |
|-----|--------|
| `DATABASE_URL` | Secret `geoapi-db` ([`k8s/secret.yaml`](k8s/secret.yaml)) |

## Layout

| Path | Role |
|------|------|
| `app.py` | App + metrics |
| `Dockerfile` | Image |
| `requirements.txt` / `test_app.py` | Deps / unit tests |
| `k8s/` | Namespace, secrets, Deployment, Service, ServiceMonitor |
| `metrics/` | Prometheus / Grafana notes |

## CI + Deploy 

→ [`../cicd/README.md`](../cicd/README.md)

## Tests

API functionality test: [`test-api.md`](test-api.md)

Unit tests:

```bash
cd api && pip install -r requirements.txt && pytest -q
```
