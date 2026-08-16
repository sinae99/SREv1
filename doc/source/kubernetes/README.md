# Kubernetes cluster bootstrap — annotated guide

This folder converts the Terraform VM output into a live Kubernetes cluster.

## What each file does

- `generate-inventory.sh` reads Terraform output and writes the Kubespray inventory.
- `kubespray.sh` runs the Kubespray installer inside Docker.
- `fetch-kubeconfig.sh` copies `admin.conf` from the control plane and rewrites the API endpoint.
- `inventory/mycluster/hosts.yaml` is the generated host map for Kubespray.
- `inventory/mycluster/group_vars/` contains the Calico and certificate SAN tuning.

## Topology

| Node | Role |
|------|------|
| `vm1` | control-plane + etcd |
| `vm2` | worker |
| `vm3` | worker |

## Read order for interviews

1. Start with `generate-inventory.sh` to show the Terraform→Ansible handoff.
2. Then explain `kubespray.sh` to show how the cluster gets installed reproducibly.
3. Finish with `fetch-kubeconfig.sh` to show how the local admin access file is produced.

## Evidence files

- `output/nodes` and `output/pods` are sample command outputs from a working cluster.
- They are useful as proof of the resulting state after the automation completes.
