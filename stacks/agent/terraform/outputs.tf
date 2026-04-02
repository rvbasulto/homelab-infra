output "agent_hostname" {
  description = "Hostname of the HCP Terraform agent LXC"
  value       = module.agent_lxc.hostname
}

output "agent_ip" {
  description = "IP address of the HCP Terraform agent LXC"
  value       = module.agent_lxc.ip_address
}

output "agent_lxc_id" {
  description = "Proxmox VMID of the HCP Terraform agent LXC"
  value       = module.agent_lxc.lxc_id
}
