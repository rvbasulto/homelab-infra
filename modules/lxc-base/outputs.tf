output "hostname" {
  description = "Hostname of the LXC container"
  value       = proxmox_lxc.this.hostname
}

output "ip_address" {
  description = "IP address of the LXC container (without CIDR suffix)"
  value       = var.ip_address
}

output "lxc_id" {
  description = "Proxmox VMID of the LXC container"
  value       = proxmox_lxc.this.vmid
}
