# subnets.tf

locals {
  # Subnets definition
  subnets = {
    "main-cni-vpc" = { # VPC Name here for the subset of rules below
      subnets = [{
        subnet_name           = "main-cni-subnet"
        subnet_ip             = "10.10.10.0/24"
        subnet_region         = var.region
        subnet_flow_logs      = "true"
        description           = "Main CNI Subnet"
        subnet_private_access = true
        }
      ]
    }
    # "multus-vpc" = {
    #   subnets = [{
    #     subnet_name           = "multus-subnet"
    #     subnet_ip             = "10.20.20.0/24"
    #     subnet_region         = var.region
    #     subnet_flow_logs      = "true"
    #     description           = "Multus Subnet"
    #     subnet_private_access = true
    #     }
    #   ]
    # }
  }
}

# Subnet Creation
module "subnets" {
  for_each     = local.subnets
  source       = "terraform-google-modules/network/google//modules/subnets"
  project_id   = var.project_id
  network_name = each.key
  subnets      = each.value.subnets
  depends_on   = [module.vpcs]
}
