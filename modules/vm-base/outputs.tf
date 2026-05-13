output "vm_id" {
  description = "VMID assigned by Proxmox."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name."
  value       = proxmox_virtual_environment_vm.this.name
}

output "ip_address" {
  description = "Configured static IP address."
  value       = var.ip_address
}
