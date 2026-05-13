module "nextcloud_lxc" {
  source = "../../../modules/lxc-base"

  proxmox_node      = var.proxmox_node
  hostname          = "nextcloud"
  lxc_template      = var.lxc_template
  lxc_root_password = var.lxc_root_password
  ssh_public_key    = var.ssh_public_key
  cores             = 4
  memory            = 2048
  rootfs_size       = 16
  ip_address        = var.nextcloud_ip
  gateway           = var.gateway
  network_bridge    = var.network_bridge
  storage           = var.storage

  nesting = true
  # Bind mount for disk2t is configured via Ansible on pve04 after LXC creation.
  # Proxmox API does not allow bind mounts for non-root@pam tokens.
}

###