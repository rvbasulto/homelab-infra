resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.proxmox_node
  unprivileged = true
  started      = true

  features {
    nesting = var.nesting
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.storage
    size         = var.rootfs_size
  }

  initialization {
    hostname = var.hostname

    dns {
      servers = [var.nameserver]
    }

    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.lxc_root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "ubuntu"
  }

  dynamic "mount_point" {
    for_each = var.mountpoints
    content {
      path   = mount_point.value.mp
      volume = mount_point.value.volume
    }
  }
}
