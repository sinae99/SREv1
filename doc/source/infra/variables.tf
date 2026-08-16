# Input surface for the Terraform module.
#
# Every value here is intentionally explicit so the interview story is clear:
# the cloud region, image, machine flavor, network layout, and SSH user are
# all controlled from a single place.

variable "api_key" {
  # Sensitive because it authenticates Terraform against Arvan Cloud.
  type      = string
  sensitive = true
}

variable "region" {
  # Region where the network and all VMs will be created.
  type = string
}

variable "distro_name" {
  # Distribution family name, used to filter Arvan's image catalog.
  type = string
}

variable "distro_version" {
  # Specific distro release, used together with `distro_name`.
  type = string
}

variable "plan_id" {
  # Arvan flavor identifier for the VM size.
  type = string
}

variable "disk_size" {
  # Root disk size for each VM, measured in GB.
  type = number
}

variable "ssh_key_name" {
  # Optional named SSH key already registered in Arvan.
  type     = string
  default  = null
  nullable = true
}

variable "ssh_user" {
  # Username used by helper scripts when connecting to the VMs.
  type = string
}

variable "network_name" {
  # Human-friendly name for the private network.
  type = string
}

variable "network_cidr" {
  # CIDR block for the private network.
  type = string
}

variable "network_gateway" {
  # Gateway IP inside the private network.
  type = string
}

variable "dhcp_start" {
  # First address in the DHCP allocation pool.
  type = string
}

variable "dhcp_end" {
  # Last address in the DHCP allocation pool.
  type = string
}

variable "vm_names" {
  # The cluster is modeled as an ordered list of VM names.
  type = list(string)
}

variable "public_ips" {
  # Manual mapping from VM name to public IP, used by later scripts.
  type        = map(string)
  description = "Public IP per VM name"
  default     = {}
}
