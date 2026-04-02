output "hostname" {
  description = "Hostname of the LXC container"
  value       = proxmox_virtual_environment_container.this.initialization[0].hostname
}

output "ip_address" {
  description = "IP address of the LXC container (without CIDR suffix)"
  value       = var.ip_address
}

output "lxc_id" {
  description = "Proxmox VMID of the LXC container"
  value       = proxmox_virtual_environment_container.this.vm_id
}
