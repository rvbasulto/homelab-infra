output "nextcloud_hostname" {
  description = "Hostname of the Nextcloud LXC container"
  value       = module.nextcloud_lxc.hostname
}

output "nextcloud_ip" {
  description = "IP address of the Nextcloud LXC container"
  value       = module.nextcloud_lxc.ip_address
}

output "nextcloud_lxc_id" {
  description = "Proxmox VMID of the Nextcloud LXC container"
  value       = module.nextcloud_lxc.lxc_id
}
