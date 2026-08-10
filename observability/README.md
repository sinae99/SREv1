# observability : Prometheus + Grafana + Alertmanager

Chart: `prometheus-community/kube-prometheus-stack`  
Namespace: `monitoring`  
Release: `cluster-monitoring`

`values.yaml`:

| Component | Role |
|-----------|------|
| Prometheus Operator | CRDs + reconciles Prometheus / Alertmanager |
| Prometheus | Scrape + store + PromQL |
| Grafana | Dashboards |
| Alertmanager | Alert routing 


---


## 1. ns

```bash
kubectl create ns monitoring
```

---

## 2. Helm repo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## 3. Helm install

```bash
cd observability

helm install cluster-monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values.yaml \
```

---

## 4. Verify

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Expect Running: prometheus-operator, prometheus, grafana, alertmanager.

---

## 6. Access (port-forwards + credentials)

```bash
./start-port-forwards.sh
./credentials.sh
```

| UI | URL |
|----|-----|
| Prometheus | localhost:9090 |
| Grafana | localhost:3000 |
| Alertmanager | localhost:9093 |

Stop:

```bash
./stop-port-forwards.sh
```

---

## files

| File | Purpose |
|------|---------|
| `values.yaml` | Helm values (prom + grafana + alertmanager only) |
| `credentials.sh` | Print Grafana admin user/password |
| `start-port-forwards.sh` | Port-forward Prometheus / Grafana / Alertmanager |
| `stop-port-forwards.sh` | Stop those port-forwards |
