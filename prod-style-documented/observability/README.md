# Observability Platform

This component installs the cluster monitoring stack with the `prometheus-community/kube-prometheus-stack` Helm chart. The supplied values intentionally enable a focused set of services: Prometheus, Grafana, Alertmanager, and node exporter.

## Enabled Components

| Component | Purpose |
|---|---|
| Prometheus | Collects and stores cluster and application metrics |
| Grafana | Visualizes node and application telemetry |
| Alertmanager | Receives and routes Prometheus alerts |
| Node exporter | Exposes host CPU, memory, filesystem, and operating system metrics |

## Monitoring Configuration

| Setting | Value |
|---|---|
| Namespace | `monitoring` |
| Helm release | `cluster-monitoring` |
| Prometheus retention | `2d` |
| Scrape interval | `60s` |
| Rule evaluation interval | `60s` |
| External ServiceMonitor discovery | Enabled |

The configuration disables unused default control-plane scraping and rule groups to keep the challenge deployment lightweight.

## Directory Structure

```text
observability/
├── values.yaml
├── credentials.sh
├── start-port-forwards.sh
├── stop-port-forwards.sh
└── dashboards/
    ├── nodes-overview.json
    └── screenshots/
```

## Installation

### 1. Create the Namespace

```bash
kubectl create namespace monitoring
```

### 2. Configure the Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 3. Install the Stack

```bash
cd observability
helm install cluster-monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml
```

## Verification

```bash
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

Prometheus, Grafana, Alertmanager, their operators or supporting components, and node exporter should report a healthy running state.

## Local Access

Start local port-forwards and print the Grafana credentials:

```bash
./start-port-forwards.sh
./credentials.sh
```

| Service | Local Address |
|---|---|
| Prometheus | `http://localhost:9090` |
| Grafana | `http://localhost:3000` |
| Alertmanager | `http://localhost:9093` |

Stop the port-forward processes when finished:

```bash
./stop-port-forwards.sh
```

## Application Monitoring

GeoAPI exposes metrics through `/metrics`. The [`../api/k8s/servicemonitor.yaml`](../api/k8s/servicemonitor.yaml) resource allows Prometheus to discover and scrape the service every 30 seconds.

## Grafana Dashboard

[`dashboards/nodes-overview.json`](dashboards/nodes-overview.json) contains the custom dashboard definition for node status, CPU, memory, and workload visibility. Recorded screenshots are stored in [`dashboards/screenshots/`](dashboards/screenshots/).

Import the dashboard through Grafana or provision it through the preferred dashboard-management workflow.

## Production Notes

- Port-forwarding is intended for administrative access, not public exposure.
- Store Grafana credentials securely and rotate them when environments change.
- Increase retention and configure persistent storage for longer-lived environments.
- Add alert rules and notification receivers according to the target operational requirements.
