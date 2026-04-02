module "agent_lxc" {
  source = "../../../modules/lxc-base"

  proxmox_node      = var.proxmox_node
  hostname          = "tfc-agent"
  lxc_template      = var.lxc_template
  lxc_root_password = var.lxc_root_password
  ssh_public_key    = var.ssh_public_key
  cores             = 1
  memory            = 512
  rootfs_size       = 8
  ip_address        = var.agent_ip
  gateway           = var.gateway
  network_bridge    = var.network_bridge
  storage           = var.storage
  nesting           = true
}
