# Arvan Cloud Infrastructure

This component provisions the cloud foundation for the challenge with Terraform. It creates a private network and three Arvan Cloud virtual machines that are later configured as a Kubernetes control plane and two workers.

## Provisioned Resources

| Resource | Purpose |
|---|---|
| Arvan private network | Provides node-to-node cluster connectivity |
| `vm1` | Kubernetes control plane and etcd node |
| `vm2` | Kubernetes worker node |
| `vm3` | Kubernetes worker node |
| Default security group | Applies the selected Arvan security group to each node |

## Technology Stack

- Terraform `>= 1.0`.
- Arvan Cloud IaaS provider `0.8.1`.
- Ansible for optional image transfer and containerd preloading.

## Directory Structure

```text
infra/
├── main.tf                 # Provider, data sources, network, and VM resources
├── variables.tf            # Typed infrastructure inputs
├── outputs.tf              # SSH user and node address map
├── terraform.tfvars        # Environment-specific variable values
├── ssh.sh                  # SSH helper for a named Terraform node
├── .ansible/inventory.yaml # Generated/recorded Ansible inventory data
└── push-load/
    ├── ansible.cfg
    ├── config.yml
    ├── config.yml.example
    ├── inventory/
    └── playbooks/push-load.yml
```

## Terraform Inputs

The configuration expects values for the Arvan API key, region, image, plan, disk size, SSH identity, network range, VM names, and public IP mapping. See [`variables.tf`](variables.tf) for the complete typed interface.

The `public_ips` map is populated after public IPs are assigned in the Arvan panel:

```hcl
public_ips = {
  vm1 = "<vm1-public-ip>"
  vm2 = "<vm2-public-ip>"
  vm3 = "<vm3-public-ip>"
}
```

## Provisioning Flow

### 1. Initialize Terraform

```bash
cd infra
terraform init
```

### 2. Provision the Network and Nodes

```bash
terraform apply
```

Wait for `vm1`, `vm2`, and `vm3` to reach the active state.

### 3. Record Public IP Addresses

Assign public IPs in the Arvan Cloud panel, add them to `terraform.tfvars`, and apply the updated mapping:

```bash
terraform apply
terraform output nodes
```

### 4. Verify SSH Access

```bash
./ssh.sh vm1
./ssh.sh vm2
./ssh.sh vm3
```

The helper reads the public addresses and SSH user from Terraform outputs.

## Terraform Outputs

| Output | Description |
|---|---|
| `ssh_user` | Remote account used by SSH and Ansible |
| `nodes` | Per-node ID, state, private address, and configured public address |

The Kubernetes inventory generator consumes these outputs directly.

## Optional: Preload Kubespray Images

The [`push-load/`](push-load/) automation supports environments where cluster nodes cannot reliably pull all required images.

The playbook can:

1. Pull configured images on the controller.
2. Save them as tar archives.
3. Copy them to each target VM.
4. Import them into containerd under the `k8s.io` namespace.
5. Verify the imported images with `crictl images`.

```bash
cd push-load
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/SINA
ansible-playbook playbooks/push-load.yml -e "@config.yml"
```

## Security and State

- Treat `terraform.tfvars` as sensitive when it contains an API key or environment-specific addresses.
- Keep Terraform state in a protected backend for shared or production use.
- Use an SSH agent for passphrase-protected private keys.
- Avoid publishing generated inventories or state data that exposes infrastructure details.
