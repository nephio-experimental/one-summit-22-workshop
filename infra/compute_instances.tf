# compute_instances.tf

locals {
  # Compute Instances parameters definition
  ssh_public_key_path  = "/home/workshop/.ssh/nephio.pub"
  ssh_private_key_path = "/home/workshop/.ssh/nephio"
  num_vms              = 1
  user                 = "ubuntu"
  # Compute Instances definition
  compute_instances = {
    "nephio-poc" = { # Prefix for each Compute Instance
      name                = "nephio-poc"
      region              = var.region
      zone                = var.zone
      num_instances       = local.num_vms
      instance_template   = module.instance_templates["cluster"].self_link
      deletion_protection = false # Protect the instance from deletion
    }
  }
}

# Public Key File Generation
resource "local_file" "public_key" {
  content  = templatefile("keys/nephio.tftpl", { pub_key = file(local.ssh_public_key_path), user = local.user })
  filename = "keys/nephio"
}

# Compute Instances Creation
module "compute_instances" {
  for_each            = { for compute_instances in local.compute_instances : compute_instances.name => compute_instances }
  source              = "terraform-google-modules/vm/google//modules/compute_instance"
  version             = "7.9.0"
  hostname            = each.key
  region              = each.value.region
  zone                = each.value.zone
  subnetwork_project  = var.project_id
  num_instances       = each.value.num_instances
  instance_template   = each.value.instance_template
  deletion_protection = each.value.deletion_protection
  depends_on          = [module.subnets, module.service_accounts, resource.google_compute_project_metadata.ssh_keys]
}

# VM configuration through bash script 
# Needs some reworking if using more than "nephio-poc" object in locals
#resource "null_resource" "config_vm" {
#  count = local.num_vms
#  connection {
#    type        = "ssh"
#    user        = local.user
#    private_key = file(local.ssh_private_key_path)
#    host        = module.compute_instances["nephio-poc"].instances_details[count.index].*.network_interface[0].*.access_config[0].*.nat_ip[0]
#  }
#
#  provisioner "remote-exec" {
#    script = "../scripts/install.sh"
#  }
#}

# # VM configuration through ansible playbooks
resource "local_file" "ansible_inventory" {
  content    = templatefile("../ansible_kind/hosts.tftpl", { hosts = { for k, vm in module.compute_instances : k => vm.instances_details[*].network_interface[0].access_config[0].nat_ip }, user = local.user })
  filename   = "../ansible_kind/hosts"
  depends_on = [module.compute_instances]
}

resource "null_resource" "config_vm" {
  provisioner "local-exec" {
    command = "ansible-playbook -i '../ansible_kind/hosts' --private-key ${local.ssh_private_key_path} ../ansible_kind/kind_setup.yaml"
  }
  //lifecycle {
  //  replace_triggered_by = [local_file.ansible_inventory]
  //}
  depends_on = [local_file.ansible_inventory]
}
