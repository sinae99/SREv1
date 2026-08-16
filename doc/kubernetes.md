# Kubernetes Deep Dive

This section explains how the VMs become a Kubernetes cluster.

## Architecture Role

The Kubernetes layer turns the three Arvan VMs into:

- `vm1` → control plane and etcd
- `vm2` → worker
- `vm3` → worker

It also creates the local artifacts that later scripts need:

- a generated Kubespray inventory
- a usable `kubeconfig`
- evidence snapshots under `kubernetes/output/`

## `doc/source/kubernetes/generate-inventory.sh`

### Input and output

- **Input:** Terraform outputs from `../infra`, specifically the `nodes` object and `ssh_user`.
- **Input validation:** checks that Terraform state exists first.
- **Output:** `inventory/mycluster/hosts.yaml` and `inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`.

### Flow

- `ROOT` and `INFRA_DIR` resolve paths relative to the script location.
- The state check prevents running the script before `terraform apply`.
- `terraform -chdir=... output -json nodes` retrieves the structured VM map.
- `terraform -chdir=... output -raw ssh_user` retrieves the SSH username.
- The embedded Python program validates that `vm1`, `vm2`, and `vm3` all exist and that each one has both public and private IPs.
- `host_block()` formats the host entries in Kubespray’s YAML structure.
- `hosts_yaml` assigns `vm1` to control-plane and etcd, and `vm2`/`vm3` to the worker pool.
- `k8s_cluster_yml` sets `kube_network_plugin: calico` and adds TLS SANs for the API server.
- `write_text()` creates the files in the Kubespray inventory tree.

### Why this matters

This script is the bridge between Terraform and Ansible: it converts infrastructure state into cluster inventory without manual editing.

## `doc/source/kubernetes/kubespray.sh`

### Input and output

- **Input:** the Kubespray inventory, SSH access, and optionally a custom command line.
- **Output:** a full cluster deployment run inside the official Kubespray container.

### Flow

- The script prefers `SSH_PRIVATE_KEY`, then `~/.ssh/SINA`, then `~/.ssh/id_rsa`.
- `KUBESPRAY_IMAGE` pins the Kubespray version to `v2.28.1`.
- `INVENTORY` points at `inventory/mycluster/hosts.yaml`.
- `mkdir -p` prepares the cache and SSH directories.
- `DOCKER_ARGS` mounts the inventory, known_hosts, and cache directories into the container.
- `ANSIBLE_EXTRA` disables host key checking inside the playbook run.
- If `ssh-agent` is available, the script mounts the agent socket into the container so Ansible can use the agent directly.
- If not, it mounts the private key file and warns that passphrase-protected keys may cause issues.
- With no arguments, it defaults to `ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml --become`.
- `docker run ...` launches the Kubespray image with the assembled mounts and arguments.

### Why this design works

Running Kubespray in a container keeps the host clean and makes the installation reproducible.

## `doc/source/kubernetes/fetch-kubeconfig.sh`

### Input and output

- **Input:** Terraform outputs, the generated inventory, and an SSH key.
- **Output:** `kubernetes/kubeconfig` ready for local `kubectl` use.

### Flow

- The script chooses an SSH key in priority order: `SSH_PRIVATE_KEY`, `~/.ssh/SINA`, then `~/.ssh/id_rsa`.
- It validates that the generated inventory already exists.
- It reads `vm1`’s public IP from Terraform output and stores it in `MASTER_PUBLIC`.
- It reads the SSH user from Terraform output.
- `ssh ... "sudo cat /etc/kubernetes/admin.conf" > kubeconfig.tmp` copies the cluster admin config from the control plane.
- The embedded Python block rewrites the API server URL from loopback or private IP to the public control-plane IP.
- The final file is saved as `kubeconfig` with mode `600`.

### Why the rewrite matters

The kubeconfig inside the node usually points to a local or private endpoint; rewriting it makes the file usable from your laptop.

## `doc/source/kubernetes/inventory/mycluster/hosts.yaml`

- This file is the generated Kubespray inventory snapshot.
- `ansible_host` stores the public address used for SSH.
- `ip` stores the private address used for node-to-node traffic.
- The `children` groups map nodes to control-plane, etcd, and worker roles.

## `doc/source/kubernetes/inventory/mycluster/group_vars/all/all.yml`

- `download_run_once: false` and the related flags tell Kubespray not to centralize downloads on just one host.
- This reduces surprising behavior in environments where each node may need its own download handling.

## `doc/source/kubernetes/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`

- `kube_network_plugin: calico` selects the CNI.
- `supplementary_addresses_in_ssl_keys` adds both the public and private control-plane addresses to the API server certificate SANs.
- This prevents TLS errors when different scripts reach the API server through different addresses.

## `doc/source/kubernetes/output/nodes` and `doc/source/kubernetes/output/pods`

- These are human-readable snapshots of `kubectl get nodes` and `kubectl get pods`.
- They are evidence artifacts, not inputs to automation.
- They help you show the interviewers the observed cluster state after installation.

## `doc/source/kubernetes/README.md`

- This README documents the operational sequence: generate inventory, install cluster, then fetch kubeconfig.
- It also identifies the node roles and the chosen stack: Kubespray, Calico, and containerd.

## Key Kubernetes Message for Interviewers

The cluster bootstrap is clean because the scripts are chained:

- Terraform produces node state
- `generate-inventory.sh` turns that state into inventory
- `kubespray.sh` installs the cluster
- `fetch-kubeconfig.sh` makes the cluster accessible locally

That is the entire control plane for the challenge in one flow.
