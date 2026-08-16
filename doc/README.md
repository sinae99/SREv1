# Arvan Cloud SRE Challenge — Documentation Pack


## files

- `doc/source/` — annotated copies of the repository files, with inline explanations.
- `doc/terraform.md` — deep dive on infrastructure provisioning.
- `doc/kubernetes.md` — cluster bootstrap, inventory generation, kubeconfig flow.
- `doc/api.md` — Flask application, tests, and Kubernetes deployment notes.
- `doc/database-observability.md` — PostgreSQL and monitoring stack walkthrough.
- `doc/cicd.md` — short delivery-pipeline summary.

## System

1. Terraform creates the Arvan VM fleet and private network.
2. Kubespray installs Kubernetes on those VMs.
3. CloudNativePG deploys PostgreSQL for caching the IP lookups.
4. kube-prometheus-stack observes the cluster and the application.
5. The Flask API resolves IPs through `ip-api.com`, caches results in Postgres, and exposes Prometheus metrics.

