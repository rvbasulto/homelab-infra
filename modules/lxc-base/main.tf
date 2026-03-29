resource "proxmox_lxc" "this" {
  target_node     = var.proxmox_node
  hostname        = var.hostname
  ostemplate      = var.lxc_template
  password        = var.lxc_root_password
  ssh_public_keys = var.ssh_public_key
  unprivileged    = true
  cores           = var.cores
  memory          = var.memory
  swap            = var.swap
  onboot          = true
  start           = true

  rootfs {
    storage = var.storage
    size    = var.rootfs_size
  }

  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = "${var.ip_address}/24"
    gw     = var.gateway
  }

  dynamic "mountpoint" {
    for_each = var.mountpoints
    content {
      slot    = mountpoint.key
      key     = tostring(mountpoint.key)
      mp      = mountpoint.value.mp
      storage = mountpoint.value.storage
      volume  = mountpoint.value.volume
      size    = mountpoint.value.size
    }
  }
}
