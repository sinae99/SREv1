api_key = "apikey dbc424ba-b700-518d-b25e-07a5ff316176"

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

vm_names = ["vm1", "vm2", "vm3"]

public_ips = {
  vm1 = "37.32.15.242"
  vm2 = "37.32.15.158"
  vm3 = "37.32.12.103"
}
