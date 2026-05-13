resource "proxmox_virtual_environment_vm" "this" {
  node_name = var.proxmox_node
  name      = var.hostname
  tags      = var.tags
  on_boot   = true

  clone {
    vm_id     = var.template_vm_id
    node_name = var.template_node
    full      = true
  }

  agent {
    enabled = true
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  keyboard_layout = "en-us"

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.storage
    ip_config {
      ipv4 {
        address = "${var.ip_address}/${var.network_prefix}"
        gateway = var.gateway
      }
    }
    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
    dns {
      servers = [var.nameserver]
      domain  = var.dns_search
    }
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      clone,
      initialization,
      description,
    ]
  }
}
