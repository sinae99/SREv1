# API

Flask service, its tests, and its Kubernetes packaging.

## Arch


- accepts an IP address as input
- checks the PostgreSQL cache first
- falls back to `ip-api.com` when the cache misses
- stores the result back into PostgreSQL
- exposes Prometheus metrics for traffic and cache size

## `app.py`

### Imports / globals

- `json`, `os`, `urllib.error`, and `urllib.request` support HTTP and configuration handling.
- `psycopg` is the PostgreSQL client.
- Flask provides the web framework and response helpers.
- `Counter`, `Gauge`, and `generate_latest` come from `prometheus_client`.
- `REQUESTS` counts calls to `/iploc`.
- `CACHED_IPS` tracks the number of rows in the cache table.
- `app = Flask(__name__)` creates the WSGI app.
- `_ready = False` is a one-time schema guard.

### DB helpers

- `get_conn()` reads `DATABASE_URL` from the environment and opens a Postgres connection.
- `ensure_schema()` creates `ip_cache` only once and then flips `_ready` to avoid repeating the DDL on every request.
- `refresh_cached_ips()` runs `SELECT COUNT(*) FROM ip_cache` and updates the gauge.
- `lookup_cache(ip)` queries the cache for a country value.
- `store_cache(ip, country)` inserts a row and ignores duplicates with `ON CONFLICT (ip) DO NOTHING`.

### External lookup

- `fetch_country(ip)` builds an `ip-api.com` URL that requests only the fields needed: `status`, `country`, and `message`.
- `urlopen(..., timeout=5)` prevents a slow upstream from hanging the request too long.
- The JSON payload is parsed and checked for `status == "success"`.
- Any non-success response raises `ValueError` with the upstream message.

### Routes

- `@app.get("/health")` returns a simple JSON health response.
- `@app.get("/metrics")` returns Prometheus exposition text generated from the registry.
- `@app.get("/iploc")` contains the core behavior:
  - increment the request counter
  - read and validate `ip` from the query string
  - ensure the schema exists
  - check the Postgres cache first
  - if cached, refresh the gauge and return the value
  - if not cached, call the external geo API, store the result, refresh the gauge, and return the lookup
  - convert database, network, timeout, and parsing failures into HTTP 502

## `test_app.py`

### What the tests prove

- `test_health()` checks the health endpoint returns `200` and the expected JSON.
- `test_iploc_missing_ip()` ensures the API rejects a missing query parameter with a client error.
- `test_metrics()` confirms the custom metrics are present and that unrelated metric names are absent.
- `test_iploc_cache_hit()` patches database helpers so the request is satisfied from cache.
- `test_iploc_cache_miss()` patches the cache to miss, then confirms the API fetches, stores, and returns the new country.
- `test_fetch_country_parses_json()` mocks `urllib.request.urlopen` and checks the JSON parser path.

### Mocking strategy

- `patch.object(...)` isolates each dependency so the test focuses on one behavior at a time.
- `MagicMock()` simulates the HTTP response object returned by `urlopen`.
- The tests are fast because they do not require a real database or external HTTP service.

## `Dockerfile`

- `FROM python:3.12-slim` gives a small base image.
- `WORKDIR /app` sets the container working directory.
- `COPY requirements.txt .` and `RUN pip install ...` install dependencies before the app code.
- `COPY app.py .` copies the application into the image.
- `EXPOSE 8000` documents the runtime port.
- `CMD ["gunicorn", ...]` starts the Flask app with a production WSGI server.

## `requirements.txt`

- `flask` powers the HTTP API.
- `gunicorn` serves the app in production.
- `psycopg[binary]` provides PostgreSQL connectivity.
- `prometheus-client` exports metrics.
- `pytest` supports the unit test suite.

## `namespace.yaml`

- Creates the `geoapi` namespace so the application has its own Kubernetes boundary.

## `secret.yaml`

- Stores `DATABASE_URL` as a Kubernetes secret

## `secret-ghcr.yaml`

- Defines a `kubernetes.io/dockerconfigjson` image pull secret.
- This is used so the cluster can pull the application image from GHCR.

## `deployment.yaml`

### Main runtime settings

- `replicas: 1` keeps the service simple for the challenge.
- `image: ghcr.io/sinae99/geoapi:latest` points at the published container image.
- `imagePullPolicy: Always` ensures fresh pulls during updates.
- `containerPort: 8000` matches the Dockerfile and Gunicorn bind address.

### Connectivity and configuration

- `imagePullSecrets` uses `ghcr-cred`.
- `hostAliases` maps `ip-api.com` to a fixed IP, which helps when external DNS is unreliable or restricted.
- `DATABASE_URL` comes from the `geoapi-db` secret.

### Health checks

- `readinessProbe` hits `/health` quickly after startup.
- `livenessProbe` uses the same endpoint to restart the pod if the process stops responding.

### Resources

- Requests and limits keep the pod lightweight and predictable.

## `service.yaml`

- Exposes the deployment inside the cluster as a `ClusterIP` service.
- Port `80` maps to the named container port `http`.

## `servicemonitor.yaml`

- Lets Prometheus scrape `/metrics` from the service.
- `namespaceSelector` and `selector` ensure the monitor targets the `geoapi` service in the right namespace.

## `test-api.md`

- This is the manual verification playbook.
- It shows how to port-forward the service, call `/health`, inspect metrics, query IPs, and validate the database cache directly.
