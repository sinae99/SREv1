# Arvan Cloud SRE Challenge — Documentation Pack

This folder is a self-contained interview pack for the repository.

## What is inside

- `doc/source/` — annotated copies of the repository files, with inline explanations.
- `doc/terraform.md` — deep dive on infrastructure provisioning.
- `doc/kubernetes.md` — cluster bootstrap, inventory generation, kubeconfig flow.
- `doc/api.md` — Flask application, tests, and Kubernetes deployment notes.
- `doc/database-observability.md` — PostgreSQL and monitoring stack walkthrough.
- `doc/cicd.md` — short delivery-pipeline summary.

## System Story

1. Terraform creates the Arvan VM fleet and private network.
2. Kubespray installs Kubernetes on those VMs.
3. CloudNativePG deploys PostgreSQL for caching the IP lookups.
4. kube-prometheus-stack observes the cluster and the application.
5. The Flask API resolves IPs through `ip-api.com`, caches results in Postgres, and exposes Prometheus metrics.

## How To Present It

- Start with the Terraform design: provider pinning, data-source discovery, and the VM/network model.
- Move to the Kubernetes scripts: inventory generation, cluster install, and kubeconfig retrieval.
- Explain the API last, because it depends on the cluster and database being in place.
- Mention observability as the proof that the system is operating, not just deployed.

## Annotated Source Mirror

The annotated source tree keeps the same directory layout as the repository:

- `doc/source/README.md`
- `doc/source/infra/`
- `doc/source/kubernetes/`
- `doc/source/database/`
- `doc/source/observability/`
- `doc/source/api/`
- `doc/source/cicd/`
- `doc/source/prod-style-documented/`

## Key Interview Angle

This project is strongest when described as an end-to-end platform:

- infrastructure provisioning
- cluster automation
- application delivery
- stateful caching
- observability and dashboards

The Terraform layer is the root of the system, so `doc/terraform.md` is the best starting point.
