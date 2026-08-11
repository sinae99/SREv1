# api metrics

App exposes Prometheus metrics at `GET /metrics`.

## ServiceMonitor

A **ServiceMonitor** tells Prometheus Operator to scrape the geoapi Service.

| Goal | Need ServiceMonitor? |
|------|----------------------|
| API works (`/iploc`, Postgres cache) | No |
| Curl `/metrics` via port-forward | No |
| Prometheus → Grafana graphs | Yes (or another scrape config) |

Keep [`../k8s/servicemonitor.yaml`](../k8s/servicemonitor.yaml) if you want Grafana panels. The API itself does not depend on it.

```bash
kubectl apply -f api/k8s/servicemonitor.yaml
```

---

## Metric catalog

| Metric | Type | Meaning |
|--------|------|---------|
| `iploc_requests_total` | Counter | Total `/iploc` calls (including bad/missing IP) |
| `iploc_cached_ips` | Gauge | Rows in `ip_cache` (`SELECT COUNT(*)`) |

---


## Files

| File | Role |
|------|------|
| [`../app.py`](../app.py) | Emits the two metrics |
| [`../k8s/servicemonitor.yaml`](../k8s/servicemonitor.yaml) | Optional Prometheus scrape |
