# Infrastructure — annotated runbook

This folder provisions the Arvan Cloud VMs and their private network.

## Read this in order

1. `terraform.tfvars` for the actual values.
2. `variables.tf` for the input surface.
3. `main.tf` for the provider, data sources, network, and VM resources.
4. `outputs.tf` for the data passed to helper scripts.
5. `ssh.sh` for the node connection flow.

## The key interview point

Terraform is the root of the platform: it resolves Arvan image and flavor IDs dynamically, creates the network, provisions the nodes, and exports a structured output that the rest of the repo consumes.
