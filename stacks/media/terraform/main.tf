module "nextcloud_lxc" {
  source = "../../../modules/lxc-base"

  proxmox_node      = var.proxmox_node
  hostname          = "nextcloud"
  lxc_template      = var.lxc_template
  lxc_root_password = var.lxc_root_password
  ssh_public_key    = var.ssh_public_key
  cores             = 4
  memory            = 2048
  rootfs_size       = "16G"
  ip_address        = var.nextcloud_ip
  gateway           = var.gateway
  network_bridge    = var.network_bridge
  storage           = var.storage

  # Bind-mount disk2t from pve04 host into the LXC.
  # IMPORTANT: Before applying, run on pve04:
  #   chown -R 100000:100000 /mnt/pve/disk2t
  mountpoints = [{
    mp      = var.disk2t_container_path
    storage = ""
    volume  = var.disk2t_host_path
    size    = "2000G"
  }]
}
