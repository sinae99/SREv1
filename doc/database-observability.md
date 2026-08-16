# Database and Observability Deep Dive

This section covers the stateful backend and the monitoring stack.

## Database Architecture

The application cache is backed by CloudNativePG, not a hand-rolled database container.

- one PostgreSQL cluster named `sina-db`
- two instances for primary/standby behavior
- a dedicated namespace (`postgres`)
- a dedicated database and user (`geoapi`)
- local-path storage for simple persistent volumes

## `doc/source/database/cluster.yaml`

### Lines 1-5: object identity

- `apiVersion: postgresql.cnpg.io/v1` selects the CloudNativePG CRD.
- `kind: Cluster` tells Kubernetes that this is a CNPG cluster resource.
- `metadata.name: sina-db` gives the database cluster its stable name.
- `metadata.namespace: postgres` isolates the database from other workloads.

### Lines 6-14: instance count and bootstrap

- `instances: 2` creates a primary plus one replica.
- `bootstrap.initdb.database: geoapi` creates the application database.
- `bootstrap.initdb.owner: geoapi` creates the matching owner user.
- `storage.size: 5Gi` keeps the state footprint small.
- `storageClass: local-path` uses the cluster’s local-path provisioner.

### Lines 15-21: resource tuning

- Requests and limits keep the Postgres pods small and schedulable.
- The values are intentionally modest because the workload is just a cache.

### Lines 22-25: PostgreSQL tuning

- `shared_buffers: "64MB"` sets a conservative memory buffer.
- `max_connections: "50"` limits concurrency to a manageable number.

### Lines 26-28: anti-affinity

- `enablePodAntiAffinity: true` encourages the primary and replica to land on different nodes.
- `topologyKey: kubernetes.io/hostname` uses the node hostname as the spreading boundary.

### Interview summary

This file shows that the database is treated as a first-class stateful workload, not a sidecar or a throwaway container.

## `doc/source/database/credentials.sh`

### Input and output

- **Input:** the `sina-db-app` secret created by CloudNativePG.
- **Output:** readable host, port, database, username, and password text.

### Flow

- The script checks that the secret exists before attempting to decode it.
- `jsonpath` extracts `username`, `password`, and `dbname` from the secret data.
- `base64 --decode` converts the Kubernetes secret values into human-readable strings.
- If `dbname` is missing, the script falls back to `geoapi`.
- The script prints the read/write service hostname `sina-db-rw.postgres.svc.cluster.local`.

## `doc/source/database/README.md`

- This is the operational database runbook.
- It explains how to install the operator, create the namespace, apply the cluster manifest, and verify the pods and services.
- It also shows the connection target that the API should use.

## Observability Architecture

The monitoring stack is intentionally focused:

- Prometheus for metrics collection
- Grafana for dashboards
- Alertmanager for alert routing
- node-exporter for node-level telemetry

## `doc/source/observability/values.yaml`

### Enabled components

- `alertmanager.enabled: true`
- `grafana.enabled: true`
- `prometheus.enabled: true`
- `prometheus-node-exporter.enabled: true`

### Prometheus tuning

- `retention: 2d` keeps the time-series footprint small.
- `scrapeInterval: 60s` and `evaluationInterval: 60s` set a simple cadence.
- `serviceMonitorSelectorNilUsesHelmValues: false` and `podMonitorSelectorNilUsesHelmValues: false` allow custom monitors to be discovered cleanly.

### Disabled components

- Cluster-control-plane and DNS-related exports are disabled.
- `kube-state-metrics` is disabled here because the challenge keeps the stack minimal.
- `defaultRules.create: false` avoids a large bundle of default alert rules.

## `doc/source/observability/start-port-forwards.sh`

### Input and output

- **Input:** the `monitoring` namespace and the services created by kube-prometheus-stack.
- **Output:** three local browser endpoints on ports `9090`, `3000`, and `9093`.

### Flow

- `svc_by_label()` queries Kubernetes by label so the script does not depend on hardcoded service names.
- It finds the Prometheus, Grafana, and Alertmanager services dynamically.
- If any service is missing, the script prints a diagnostic message and exits.
- The three `kubectl port-forward` commands run in the background and write PIDs to `/tmp`.
- The script prints the URLs and points the user at `credentials.sh` and `stop-port-forwards.sh`.

## `doc/source/observability/stop-port-forwards.sh`

- Stops the background port-forwards by reading their PID files from `/tmp`.
- Removes the pidfiles after killing the processes.

## `doc/source/observability/credentials.sh`

- Finds the Grafana secret by label rather than by exact name.
- Decodes the admin username and password from the secret data.
- Prints the local Grafana URL and credentials for quick access.

## `doc/source/observability/README.md`

- This README is the install-and-use guide for the monitoring stack.
- It covers namespace creation, Helm repo setup, Helm install, verification, and port-forward access.
- The file list at the end explains where the dashboards and helper scripts live.

## `doc/source/observability/dashboards/`

- `nodes-overview.json` is the infrastructure dashboard.
- `geoapi-overview.json` is the service dashboard.
- The screenshots under `screenshots/` provide visual proof of the dashboards in Grafana.

## `doc/source/cicd/README.md`

- Summarizes the delivery chain: push, test, build, push to GHCR, deploy to Kubernetes.
- It is a documentation-only overview in this repo snapshot.

## Key Database and Observability Message for Interviewers

The platform is not just deployed — it is observable and stateful:

- the API writes to a real Postgres cluster
- Prometheus can scrape the application and the cluster
- Grafana shows the health of both the platform and the service
- helper scripts make access reproducible
