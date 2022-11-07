# compute_instances.tf

locals {
  # Compute Instances definition
  compute_instances = {
    "nephio-poc" = { # Prefix for each Compute Instance
      name                = "nephio-poc"
      region              = var.region
      zone                = var.zone
      num_instances       = 1
      instance_template   = module.instance_templates["cluster"].self_link
      deletion_protection = false # Protect the instance from deletion
    }
  }
}

# Compute Instances Creation
module "compute_instances" {
  for_each            = { for compute_instances in local.compute_instances : "${compute_instances.name}" => compute_instances }
  source              = "terraform-google-modules/vm/google//modules/compute_instance"
  hostname            = each.key
  region              = each.value.region
  zone                = each.value.zone
  subnetwork_project  = var.project_id
  num_instances       = each.value.num_instances
  instance_template   = each.value.instance_template
  deletion_protection = each.value.deletion_protection
  depends_on          = [module.subnets, module.service_accounts, resource.google_compute_project_metadata.ssh_keys]
}
