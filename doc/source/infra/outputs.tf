# Terraform outputs are the handoff point to the rest of the repo.
#
# `ssh.sh`, `generate-inventory.sh`, and `fetch-kubeconfig.sh` all read these
# outputs instead of hardcoding IP addresses or usernames.

locals {
  # Normalize the `public_ips` map so every VM name exists in the output.
  public_ip_for = {
    for name in var.vm_names : name => try(var.public_ips[name], null)
  }
}

output "ssh_user" {
  # Helper scripts read this so the login user stays centralized in Terraform.
  value = var.ssh_user
}

output "nodes" {
  # Return a structured per-node object rather than a plain text list.
  value = {
    for name, vm in arvan_abrak.node : name => {
      id = vm.id
      # `status` is useful for waiting on creation and for interview demos.
      status = vm.status
      # Find the first private network address; leave `null` if nothing matches.
      private = try([for n in vm.networks : n.ip if !n.is_public && n.ip != ""][0], null)
      # Public IPs are user-supplied later from the Arvan panel.
      public = local.public_ip_for[name]
    }
  }
}
