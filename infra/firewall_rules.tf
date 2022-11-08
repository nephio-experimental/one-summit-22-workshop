# firewall_rules.tf

locals {
  # Firewall Rules definition
  firewall_rules = {
    "main-cni-vpc" = { # VPC Name here for the subset of rules below
      rules = [{
        name                    = "allow-ssh-ingress"
        description             = "Permit SSH into the VM"
        direction               = "INGRESS"
        priority                = null
        ranges                  = ["0.0.0.0/0"]
        source_tags             = null
        source_service_accounts = null
        target_tags             = ["ssh"]
        target_service_accounts = null
        allow = [{
          protocol = "tcp"
          ports    = ["22"]
        }]
        deny = []
        log_config = {
          metadata = "INCLUDE_ALL_METADATA"
        }
        }
      ]
    }
  }
}

# Firewall Rules Creation
module "firewall_rules" {
  for_each     = local.firewall_rules
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "5.2.0"
  project_id   = var.project_id
  network_name = each.key
  rules        = each.value.rules
  depends_on   = [module.vpcs]
}

