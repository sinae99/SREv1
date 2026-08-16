# GeoAPI metrics

The application exposes Prometheus metrics at `GET /metrics`.

## What gets scraped

- `iploc_requests_total` counts `/iploc` requests.
- `iploc_cached_ips` reports the number of rows in the cache table.

## How scraping is enabled

Apply `k8s/servicemonitor.yaml` so kube-prometheus-stack discovers the service.
