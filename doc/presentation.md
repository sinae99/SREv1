# Repository Presentation Guide

Use this as a speaking order when you present the repo. The goal is to tell a clear story from foundation to delivery:

**1. Start with the big picture**
- Open with `README.md`.
- Say this repo is an end-to-end SRE/platform challenge: infrastructure, Kubernetes, database, observability, API, and CI/CD.
- Mention that each folder is one layer of the system, not an isolated demo.

**2. Present the infrastructure first**
- Move to `infra/README.md`.
- Then explain the Terraform files in this order:
  - `infra/variables.tf` — what inputs the stack needs.
  - `infra/main.tf` — what resources Terraform creates.
  - `infra/outputs.tf` — what the rest of the repo consumes.
  - `infra/terraform.tfvars` — the actual values used in this challenge.
  - `infra/ssh.sh` — the helper that makes the VMs easy to access.
- Tell the audience that infrastructure comes first because every later step depends on these VMs and outputs.

**3. Explain the Kubernetes bootstrap**
- Continue with `kubernetes/README.md`.
- Then present the scripts in this order:
  - `kubernetes/generate-inventory.sh` — converts Terraform state into Ansible inventory.
  - `kubernetes/kubespray.sh` — installs the cluster.
  - `kubernetes/fetch-kubeconfig.sh` — makes the cluster usable locally.
- Say the story is “Terraform creates nodes, then Kubespray turns them into a cluster.”

**4. Cover the stateful backend and observability together**
- Move to `database/README.md` and `observability/README.md`.
- For the database, explain that CloudNativePG gives the API a real PostgreSQL backend and cache.
- For observability, explain that Prometheus, Grafana, and Alertmanager prove the platform is healthy.
- If you want to go deeper, mention:
  - `database/cluster.yaml`
  - `database/credentials.sh`
  - `observability/values.yaml`
  - `observability/start-port-forwards.sh`
  - `observability/credentials.sh`

**5. Present the application last**
- Move to `api/README.md`.
- Then explain the implementation flow:
  - `api/app.py` — the Flask service.
  - `api/test_app.py` — how the behavior is verified.
  - `api/k8s/namespace.yaml`, `api/k8s/secret.yaml`, `api/k8s/deployment.yaml`, `api/k8s/service.yaml`, `api/k8s/servicemonitor.yaml` — how it runs on Kubernetes.
- Say the API is the user-facing part, but it depends on the cluster and database already being in place.

**6. Finish with delivery**
- Close with `cicd/README.md`.
- Mention the delivery chain: test, build, publish, deploy.
- Position CI/CD as the last layer, because it automates everything above it.

## Best Talking Order For Each Layer

When you explain a folder, use this professional order:

1. `README.md` for the folder
2. inputs or variables
3. main resources or core logic
4. outputs or generated artifacts
5. helper scripts and operational flow

That pattern works well for Terraform, Kubernetes scripts, the database, observability, and the API.

## Suggested Narrative

You can present the repo with a simple sentence at each step:

- “First, Terraform provisions the VMs and private network.”
- “Next, Kubespray turns those VMs into a three-node Kubernetes cluster.”
- “Then CloudNativePG gives the API a persistent PostgreSQL cache.”
- “Prometheus and Grafana show that the system is actually observable.”
- “Finally, the Flask API exposes the service and the CI/CD docs show how delivery would work.”

## What Not To Do

- Do not start with deep implementation details before explaining the system goal.
- Do not jump directly to `terraform.tfvars` before the audience understands what Terraform is building.
- Do not present the API before the cluster and database, because it depends on both.
- Do not spend too long on one file; keep moving from architecture to implementation to proof.

## Short Version You Can Say Out Loud

“I’ll start with the repo overview, then walk through infrastructure, Kubernetes, database and observability, the API, and finally CI/CD. Inside each section, I explain the README first, then the inputs, then the core logic, then the outputs and helper scripts. That gives a clean story from provisioning all the way to delivery.”
