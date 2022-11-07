# outputs.tf

output "name" {
  description = "VM Name"
  value       = { for k, vm in module.compute_instances : k => vm.*.instances_details[0].*.name }
}

output "ip" {
  description = "VM External IP"
  value       = { for k, vm in module.compute_instances : k => vm.*.instances_details[0].*.network_interface[0].*.access_config[0].*.nat_ip[0] }
}

