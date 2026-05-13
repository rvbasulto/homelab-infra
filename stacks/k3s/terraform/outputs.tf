output "k3s_vm_names" {
  description = "Names of provisioned k3s VMs."
  value       = [for vm in module.k3s_vms : vm.name]
}

output "k3s_vm_ipv4" {
  description = "Mapping of VM names to IPv4 addresses."
  value       = { for name, vm in module.k3s_vms : name => vm.ip_address }
}
