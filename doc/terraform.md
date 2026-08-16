# Terraform and Infra

## Arch

Terraform is responsible for:

- discovering the right Arvan Cloud image and plan at runtime
- creating the private network for node-to-node traffic
- provisioning the three VMs used by Kubespray
- exposing private/public IPs in a structured output for later automation

## `main.tf`

### Terraform and provider setup

- `terraform {}` starts the root configuration block.
- `required_version = ">= 1.0"` prevents accidental use of old Terraform behavior.
- `required_providers` pins the Arvan provider source and exact version.
- `provider "arvan" { api_key = var.api_key }` injects the API key from configuration instead of hardcoding it.

### runtime discovery

- `data "arvan_security_groups" "default"` fetches the default security group for the selected region.
- `data "arvan_images" "distributions"` asks Arvan for distribution images.
- `data "arvan_plans" "plans"` asks Arvan for available VM flavors.
- `locals.chosen_image` uses a `for` expression plus `one([...])` to select exactly one Ubuntu image by distro name and version.
- `locals.selected_plan` uses the same pattern to resolve the flavor id from `var.plan_id`.

### private network

- `resource "arvan_network" "cluster"` creates a dedicated private network.
- `description`, `name`, `cidr`, and `gateway_ip` describe the network identity and routing.
- `dhcp_range` defines the automatic IP range handed out to the VMs.
- `dns_servers` configures resolver addresses for the private network.
- `enable_dhcp` and `enable_gateway` turn on the two behaviors the cluster needs.

### VM provisioning

- `resource "arvan_abrak" "node"` provisions the three instances.
- `for_each = toset(var.vm_names)` creates one instance per node name, which keeps the Terraform code compact and deterministic.
- `depends_on = [arvan_network.cluster]` forces the network to exist before the VMs are attached.
- `timeouts { ... }` gives Arvan enough time for slow create/update operations.
- `image_id = local.chosen_image.id` and `flavor_id = local.selected_plan.id` connect the VM to the resolved image and plan.
- `ssh_key_name = var.ssh_key_name` makes SSH access configurable.
- `networks = [{ network_id = arvan_network.cluster.network_id }]` attaches the VM to the private network.
- `security_groups = [data.arvan_security_groups.default.groups[0].id]` uses the default security group for basic access control.

## `variables.tf`

- `api_key` is marked `sensitive = true` so Terraform treats it carefully.
- `region`, `distro_name`, `distro_version`, and `plan_id` control the VM template selection.
- `disk_size`, `ssh_key_name`, and `ssh_user` control machine shape and login method.
- `network_name`, `network_cidr`, `network_gateway`, `dhcp_start`, and `dhcp_end` define the private network layout.
- `vm_names` is the only place where the node count is expressed.
- `public_ips` is an optional map used later by scripts and outputs to remember the panel-assigned public addresses.

## `outputs.tf`

- `locals.public_ip_for` converts the `public_ips` map into a complete node-name map with `null` fallback values.
- `output "ssh_user"` exposes the login user for helper scripts.
- `output "nodes"` returns a structured object per VM.
- `private = try([for n in vm.networks : n.ip if !n.is_public && n.ip != ""][0], null)` extracts the first private IP safely.
- `public = local.public_ip_for[name]` merges the manually entered public IPs into the output object.

This output shape is the glue for `ssh.sh`, `generate-inventory.sh`, and `fetch-kubeconfig.sh`.

## `terraform.tfvars`

- These values instantiate the abstract Terraform variables.
- `region`, `distro_name`, and `distro_version` select Ubuntu 24.04 in the Tehran region.
- `plan_id` and `disk_size` define VM capacity.
- `vm_names = ["vm1", "vm2", "vm3"]` gives the cluster its fixed three-node topology.
- `public_ips` stores the panel-side addresses used later by SSH and Kubernetes inventory generation.

## `ssh.sh`

### Input and output

- **Input:** a VM name such as `vm1`, plus optional `ssh` flags.
- **Input source:** Terraform state via `terraform output -json nodes` and `terraform output -raw ssh_user`.
- **Output:** an interactive SSH session to the chosen Arvan VM.

### Flow

- `cd "$(dirname "$0")"` makes the script run relative to `infra/`.
- `list_hosts()` prints the known VM names with public and private IPs for discoverability.
- `usage()` prints the command format and exits when no VM name is given.
- The `python3` snippets parse Terraform JSON because JSON object selection is safer than shell text parsing.
- `IP="$(...)"` chooses the public IP first, then falls back to the private IP.
- `USER="$(terraform output -raw ssh_user)"` keeps the login name in sync with Terraform.
- `exec ssh -o StrictHostKeyChecking=accept-new ...` replaces the script process with SSH and avoids repeated host-key prompts.
