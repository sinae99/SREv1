
## planning

1 - create VMs via Terraform

[infra/README.md](infra/README.md)

------

2 - create 3-node kubernetes cluster via Ansible

[kubernetes/README.md](kubernetes/README.md)

------

3 - implement monitoring for cluster via Prometheus

[observability/README.md](observability/README.md)

------

4 - create dashboard in Grafana

[observability/dashboards](observability/dashboards)

------

5 - set up Alerting

[observability/alerts](observability/alerts)

------

6 - deploy postgres cluster

[database/README.md](database/README.md)

------


### scenario - 1

1 - create a web api that get ip as input and return ip geolocation

2 - save outputs in postgres and use it as cache

3 - deploy api on kubernetes cluster

[api/README.md](api/README.md) — Flask app + Dockerfile + `api/k8s/` manifests

4 - CI/CD (GitHub Actions → GHCR → cluster)

[cicd/README.md](cicd/README.md)
