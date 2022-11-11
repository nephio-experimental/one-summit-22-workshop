# kind-cluster-gce

Terraform code to provision Kind clusters on top of GCE Instances

## requirements

- [terraform 1.3.2](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## usage

- Generate the SSH Key on your local machine:

```bash
ssh-keygen -t rsa -f ~/.ssh/nephio -C nephio -b 2048
```

- Fill in the required parameters in compute_instances.tf file:

```bash
  # Compute Instances parameters definition
  ssh_public_key_path  = "xxxxx"
  ssh_private_key_path = "xxxxx"
  num_vms              = NUMBER
  user                 = "ubuntu"  - must be this one unless we autogenerate the kind_setup.yaml as it is performed on the ansible hosts inventory
```

- Choose if you want to configure the VMs through the script method or through and ansible role by uncommenting the specific section in compute_instances.tf file:

```bash
# # VM configuration through bash script 
# # Needs some reworking if using more than "nephio-poc" object in locals
# resource "null_resource" "config_vm" {
#   count = local.num_vms
#   connection {
#     type        = "ssh"
#     user        = local.user
#     private_key = file(local.ssh_private_key_path)
#     host        = module.compute_instances["nephio-poc"].instances_details[count.index].*.network_interface[0].*.access_config[0].*.nat_ip[0]
#   }

#   provisioner "remote-exec" {
#     script = "../scripts/startup.sh"
#   }
# }
```

OR

```bash
# # VM configuration through ansible playbooks
# resource "local_file" "ansible_inventory" {
#   content    = templatefile("../ansible_kind/hosts.tftpl", { hosts = { for k, vm in module.compute_instances : k => vm.instances_details[*].*.network_interface[0].*.access_config[0].*.nat_ip[0] }, user = local.user })
#   filename   = "../ansible_kind/hosts"
#   depends_on = [module.compute_instances]
# }

# resource "null_resource" "config_vm" {
#   provisioner "local-exec" {
#     command = "ansible-playbook -i '../ansible_kind/hosts' --private-key ${local.ssh_private_key_path} ../ansible_kind/kind_setup.yaml"
#   }
#   depends_on = [local_file.ansible_inventory]
# }
```

- Change the parameters in the general.auto.tfvars file:

```bash
# General Settings
project_id = "xxxxx"
region     = "xxxxx"
zone       = "xxxxx"
```

- To run the terraform code locally run:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project PROJECT_ID
terraform init
terraform plan
terraform apply
```

## VM Access

To access the VM after creation run:

```bash
ssh ubuntu@IP -i ~/.ssh/nephio
```
