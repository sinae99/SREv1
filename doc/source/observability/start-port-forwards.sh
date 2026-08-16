#!/usr/bin/env bash

# Keep port-forward helper scripts safe and deterministic.
set -euo pipefail

NAMESPACE="monitoring"

# Find a service name by label instead of assuming the chart-generated name.
svc_by_label() {
  local label="$1"
  kubectl -n "${NAMESPACE}" get svc -l "${label}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true
}

# kube-prometheus-stack uses different labels for each component.
PROM_SVC=$(svc_by_label "app=kube-prometheus-stack-prometheus")
GRAF_SVC=$(svc_by_label "app.kubernetes.io/name=grafana")
AM_SVC=$(svc_by_label "app=kube-prometheus-stack-alertmanager")

# Fail clearly if any service is missing.
if [[ -z "${PROM_SVC}" || -z "${GRAF_SVC}" || -z "${AM_SVC}" ]]; then
  echo "Could not find services in ${NAMESPACE}."
  echo "  prometheus:   ${PROM_SVC:-missing}"
  echo "  grafana:      ${GRAF_SVC:-missing}"
  echo "  alertmanager: ${AM_SVC:-missing}"
  echo "Is the stack installed? kubectl get svc -n ${NAMESPACE}"
  exit 1
fi

echo "Starting port-forwards in background..."
echo "  Prometheus:   http://localhost:9090  (svc/${PROM_SVC})"
echo "  Grafana:      http://localhost:3000  (svc/${GRAF_SVC})"
echo "  Alertmanager: http://localhost:9093  (svc/${AM_SVC})"

# Each port-forward runs in the background and records its PID for later stop.
kubectl -n "${NAMESPACE}" port-forward "svc/${PROM_SVC}" 9090:9090 >/tmp/pf-prometheus.log 2>&1 &
echo $! > /tmp/pf-prometheus.pid

kubectl -n "${NAMESPACE}" port-forward "svc/${GRAF_SVC}" 3000:80 >/tmp/pf-grafana.log 2>&1 &
echo $! > /tmp/pf-grafana.pid

kubectl -n "${NAMESPACE}" port-forward "svc/${AM_SVC}" 9093:9093 >/tmp/pf-alertmanager.log 2>&1 &
echo $! > /tmp/pf-alertmanager.pid

echo "Done."
echo "Credentials: ./credentials.sh"
echo "To stop:     ./stop-port-forwards.sh"
