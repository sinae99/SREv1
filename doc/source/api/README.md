# API — annotated overview

This service is the user-facing IP geolocation component.

## Request flow

1. Client calls `GET /iploc?ip=<address>`.
2. The app checks PostgreSQL for a cached answer.
3. On cache miss, the app calls `ip-api.com`.
4. The new answer is stored back into PostgreSQL.
5. The response is returned as JSON and metrics are updated.

## File map

- `app.py` contains the runtime logic.
- `test_app.py` verifies the behavior with mocked dependencies.
- `Dockerfile` builds the production image.
- `requirements.txt` lists the runtime and test dependencies.
- `k8s/` contains the Kubernetes manifests.
- `metrics/README.md` explains the Prometheus integration.

## Why this folder matters

This is the only user-facing service in the challenge, so it demonstrates the full path from input validation to external API lookup, caching, metrics, and deployment.
