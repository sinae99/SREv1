# Terraform entry point for the Arvan VM layer.
#
# This file is intentionally annotated for interview review:
# - what each block does
# - why each variable or expression exists
# - how the VM and network pieces connect together

terraform {
  # Require a modern Terraform engine so provider behavior is stable.
  required_version = ">= 1.0"

  # Pin the exact Arvan provider source and version.
  required_providers {
    arvan = {
      source  = "terraform.arvancloud.ir/arvancloud/iaas"
      version = "0.8.1"
    }
  }
}

# The provider block gives Terraform the credentials it needs to talk to Arvan.
provider "arvan" {
  # `var.api_key` comes from `terraform.tfvars` and is marked sensitive.
  api_key = var.api_key
}

# Read the default security groups available in the chosen region.
data "arvan_security_groups" "default" {
  region = var.region
}

# Read all distribution images so we can select the exact Ubuntu release.
data "arvan_images" "distributions" {
  region     = var.region
  image_type = "distributions"
}

# Read all VM plans so we can select the exact flavor id by plan id.
data "arvan_plans" "plans" {
  region = var.region
}

# Local values are computed once and reused by multiple resources.
locals {
  # Find exactly one image that matches both distro name and version.
  # `one([...])` guarantees the result is a single object, not a list.
  chosen_image = one([
    for image in data.arvan_images.distributions.distributions : image
    if image.distro_name == var.distro_name && image.name == var.distro_version
  ])

  # Find exactly one plan whose provider id matches `var.plan_id`.
  selected_plan = one([
    for plan in data.arvan_plans.plans.plans : plan
    if plan.id == var.plan_id
  ])
}

# Create the private network that all cluster nodes attach to.
resource "arvan_network" "cluster" {
  region      = var.region
  description = "private network"
  name        = var.network_name

  # DHCP range defines the dynamic private-address pool.
  dhcp_range = {
    start = var.dhcp_start
    end   = var.dhcp_end
  }

  # DNS servers are made available inside the private network.
  dns_servers    = ["8.8.8.8", "1.1.1.1", "178.22.122.100", "185.51.200.2"]
  enable_dhcp    = true
  enable_gateway = true
  cidr           = var.network_cidr
  gateway_ip     = var.network_gateway
}

# Create one VM per name in `var.vm_names`.
# `for_each` keeps the code short while still producing three explicit nodes.
resource "arvan_abrak" "node" {
  for_each = toset(var.vm_names)

  # The VMs must wait for the private network to exist first.
  depends_on = [arvan_network.cluster]

  # Timeouts prevent long Arvan operations from being killed too early.
  timeouts {
    create = "45m"
    update = "45m"
    delete = "20m"
    read   = "10m"
  }

  region       = var.region
  name         = each.key
  image_id     = local.chosen_image.id
  flavor_id    = local.selected_plan.id
  disk_size    = var.disk_size
  enable_ipv4  = true
  ssh_key_name = var.ssh_key_name

  # Attach the VM to the private cluster network.
  networks = [
    {
      network_id = arvan_network.cluster.network_id
    }
  ]

  # Use the region default security group for basic reachability.
  security_groups = [data.arvan_security_groups.default.groups[0].id]
}
