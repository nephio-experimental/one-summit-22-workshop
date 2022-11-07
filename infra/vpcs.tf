# vpcs.tf

locals {
  # VPCs definition
  vpcs = {
    "main-cni-vpc" = { # Name of each VPC to create
    }
    # "multus-vpc" = {
    # }
  }
}

# VPC Creation
module "vpcs" {
  for_each     = local.vpcs
  source       = "terraform-google-modules/network/google//modules/vpc"
  project_id   = var.project_id
  network_name = each.key
}
