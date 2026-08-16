# Observability — annotated guide

This folder explains how monitoring is installed and accessed.

## Components kept in the stack

- Prometheus
- Grafana
- Alertmanager
- node-exporter

## How to read the helpers

- `values.yaml` shows which parts of kube-prometheus-stack are enabled.
- `start-port-forwards.sh` opens local browser ports for the UIs.
- `credentials.sh` prints the Grafana login.
- `stop-port-forwards.sh` closes the port-forward processes.

## Why the stack is scoped this way

The configuration is intentionally small so it is easy to explain in an interview while still covering the essential platform signals: cluster health, dashboarding, alerts, and application metrics.
