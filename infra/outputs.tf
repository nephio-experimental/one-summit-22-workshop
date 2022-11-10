# outputs.tf

# output "vm_names" {
#   description = "VM Name"
#   value       = { for k, vm in module.compute_instances : k => vm.*.instances_details[0].*.name }
# }

# output "vm_external_ips" {
#   description = "VM External IP"
#   value       = { for k, vm in module.compute_instances : k => vm.instances_details[*].*.network_interface[0].*.access_config[0].*.nat_ip[0] }
# }



output "vm_names" {
  description = "VM Name"
  value       = google_compute_instance_from_machine_image.vms.*.name
}

output "vm_external_ips" {
  description = "VM External IP"
  value       = google_compute_instance_from_machine_image.vms.*.network_interface.0.access_config.0.nat_ip
}
