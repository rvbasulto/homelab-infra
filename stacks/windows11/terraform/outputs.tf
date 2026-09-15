output "vm_id" {
  description = "Windows 11 VMID"
  value       = proxmox_virtual_environment_vm.windows11.vm_id
}

output "vm_name" {
  description = "Windows 11 VM name"
  value       = proxmox_virtual_environment_vm.windows11.name
}
