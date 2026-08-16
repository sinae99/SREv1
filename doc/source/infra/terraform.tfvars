# Concrete values used for the challenge environment.
#
# These are the real instantiation values for the abstract variables in
# `variables.tf`.

api_key = "x"

region         = "ir-thr-ba1"
distro_name    = "ubuntu"
distro_version = "24.04"

plan_id   = "g2-4-2-0"
disk_size = 40

ssh_key_name = null
ssh_user     = "ubuntu"

network_name    = "private-192"
network_cidr    = "192.168.1.0/24"
network_gateway = "192.168.1.1"
dhcp_start      = "192.168.1.100"
dhcp_end        = "192.168.1.254"

# The cluster intentionally stays three-node and fixed-size.
vm_names = ["vm1", "vm2", "vm3"]

# These public IPs are later reused by SSH and Kubernetes inventory generation.
public_ips = {
  vm1 = "37.32.15.242"
  vm2 = "37.32.15.158"
  vm3 = "37.32.12.103"
}
