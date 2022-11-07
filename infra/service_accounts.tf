# service_accounts.tf

locals {
  # Service Accounts definition
  service_accounts = {
    "compute" = { # Name of each SA Prefix
      names        = ["general"]
      descriptions = ["General Purpose SA"]
      project_roles = [ # Service account allowed permissions
        # "${var.project_id}=>roles/storage.admin"
      ]
    }
  }
}

# Service Accounts Creation
module "service_accounts" {
  for_each      = local.service_accounts
  source        = "terraform-google-modules/service-accounts/google"
  version       = "4.1.1"
  project_id    = var.project_id
  prefix        = each.key
  names         = each.value.names
  descriptions  = each.value.descriptions
  project_roles = each.value.project_roles
}
