# compute_instances.tf

locals {
  # Compute Instances parameters definition
  ssh_public_key_path  = "xxxxx"
  ssh_private_key_path = "xxxxx"
  num_vms              = 2
  user                 = "ubuntu"
  # Compute Instance Full Template definition
  compute_instances = {
    "nephio-poc-template" = { # Prefix for each Compute Instance
      name                = "nephio-poc-template"
      region              = var.region
      zone                = var.zone
      num_instances       = 1
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

# Compute Instance Full Template Creation
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
resource "null_resource" "config_vm" {
  for_each = { for compute_instances in local.compute_instances : compute_instances.name => compute_instances }
  connection {
    type        = "ssh"
    user        = local.user
    private_key = file(local.ssh_private_key_path)
    host        = module.compute_instances[each.key].instances_details[0].*.network_interface[0].*.access_config[0].*.nat_ip[0]
  }

  provisioner "remote-exec" {
    script = "../scripts/install.sh"
  }
}

# # VM configuration through ansible playbooks
# resource "local_file" "ansible_inventory" {
#   content    = templatefile("../ansible_kind/hosts.tftpl", { host = module.compute_instances["nephio-poc-template"].instances_details[0].*.network_interface[0].*.access_config[0].*.nat_ip[0], user = local.user })
#   filename   = "../ansible_kind/hosts"
#   depends_on = [module.compute_instances]
# }

# resource "null_resource" "config_vm" {
#   provisioner "local-exec" {
#     command = "ansible-playbook -i '../ansible_kind/hosts' --private-key ${local.ssh_private_key_path} ../ansible_kind/kind_setup.yaml"
#   }
#   depends_on = [local_file.ansible_inventory]
# }


# Compute Instances from Full Template VM Creation
resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name            = "nephio-poc-template"
  source_instance = module.compute_instances["nephio-poc-template"].instances_details[0].self_link
  depends_on      = [null_resource.config_vm]
}

resource "google_compute_instance_from_machine_image" "vms" {
  count                = local.num_vms
  provider             = google-beta
  zone                 = var.zone
  name                 = "nephio-participant-${count.index}"
  source_machine_image = google_compute_machine_image.image.self_link
}

# Generate an Inventory File with the VM Name and External IP
resource "local_file" "inventory" {
  content    = <<EOT
%{for vm_name, vm_ip in zipmap(google_compute_instance_from_machine_image.vms.*.name, google_compute_instance_from_machine_image.vms.*.network_interface.0.access_config.0.nat_ip)~}
${vm_name},${vm_ip}
%{endfor~}
  EOT
  filename   = "inventory"
  depends_on = [google_compute_instance_from_machine_image.vms]
}
