# Kubernetes Cluster with Kubespray

This component converts the Terraform-provisioned virtual machines into a three-node Kubernetes cluster. Kubespray runs from its official container image, while local helper scripts generate inventory data, install the cluster, and retrieve administrator access.

## Cluster Topology

| Node | Role | Connectivity |
|---|---|---|
| `vm1` | Control plane and etcd | Public SSH and private cluster address |
| `vm2` | Worker | Public SSH and private cluster address |
| `vm3` | Worker | Public SSH and private cluster address |

## Cluster Stack

- Kubespray `v2.28.1`.
- Kubernetes `v1.30.x` target environment.
- Calico CNI.
- containerd CRI.
- Terraform-generated Ansible inventory.

## Directory Structure

```text
kubernetes/
├── generate-inventory.sh
├── kubespray.sh
├── fetch-kubeconfig.sh
├── inventory/mycluster/
│   ├── hosts.yaml
│   └── group_vars/
├── output/
│   ├── nodes
│   └── pods
└── .gitignore
```

## Installation Flow

### 1. Generate the Inventory

The generator reads `nodes` and `ssh_user` from the Terraform outputs in [`../infra/`](../infra/README.md), validates that all three nodes have public and private addresses, and writes the Kubespray inventory.

```bash
cd kubernetes
./generate-inventory.sh
```

Generated files:

- `inventory/mycluster/hosts.yaml`
- `inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`

### 2. Install the Cluster

For a passphrase-protected key, load the key into an SSH agent before starting Kubespray:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/SINA
./kubespray.sh
```

With no custom arguments, the wrapper runs the Kubespray `cluster.yml` playbook against `inventory/mycluster/hosts.yaml` with privilege escalation.

### 3. Fetch the Administrator Kubeconfig

```bash
./fetch-kubeconfig.sh
export KUBECONFIG="$(pwd)/kubeconfig"
kubectl get nodes
```

The helper copies `/etc/kubernetes/admin.conf` from `vm1`, rewrites the API server endpoint to the configured public address, and stores the result with mode `0600`.

## Configuration Files

| File | Purpose |
|---|---|
| `inventory/mycluster/hosts.yaml` | Maps public SSH addresses, private node addresses, and cluster roles |
| `group_vars/all/all.yml` | Controls Kubespray download behavior |
| `group_vars/k8s_cluster/k8s-cluster.yml` | Selects Calico and adds API server certificate addresses |
| `generate-inventory.sh` | Regenerates inventory from Terraform outputs |
| `kubespray.sh` | Runs Kubespray through Docker with SSH agent or key support |
| `fetch-kubeconfig.sh` | Retrieves and rewrites the administrator kubeconfig |

## Verification

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

Expected state:

- All three nodes report `Ready`.
- `vm1` reports the control-plane role.
- `vm2` and `vm3` are schedulable workers.
- System workloads are running across the cluster.

Recorded command outputs are available in [`output/nodes`](output/nodes) and [`output/pods`](output/pods).

## Operational Notes

- Regenerate inventory after Terraform addresses change.
- Keep the kubeconfig private and outside version control.
- The `kubespray_cache/` directory is local runtime data and is intentionally ignored.
- Use the image preload automation in [`../infra/push-load/`](../infra/README.md#optional-preload-kubespray-images) when registry access is unreliable.
