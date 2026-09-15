output "vm_id" {
  description = "Windows 11 VMID"
  value       = proxmox_virtual_environment_vm.windows11.vm_id
}

output "vm_name" {
  description = "Windows 11 VM name"
  value       = proxmox_virtual_environment_vm.windows11.name
}

output "virtio_iso_file_id" {
  description = "Downloaded VirtIO ISO file ID"
  value       = proxmox_virtual_environment_download_file.virtio_win_iso.id
}
