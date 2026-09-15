resource "proxmox_virtual_environment_download_file" "virtio_win_iso" {
  content_type = "iso"
  datastore_id = var.iso_storage
  node_name    = var.proxmox_node
  file_name    = "virtio-win.iso"
  url          = var.virtio_iso_url
}

resource "proxmox_virtual_environment_vm" "windows11" {
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  name      = var.hostname
  tags      = var.tags
  on_boot   = var.on_boot
  started   = var.started

  machine = "q35"
  bios    = "ovmf"

  operating_system {
    type = "win11"
  }

  agent {
    enabled = var.qemu_agent_enabled
    type    = "virtio"
  }

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  efi_disk {
    datastore_id      = var.storage
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = true
  }

  tpm_state {
    datastore_id = var.storage
    version      = "v2.0"
  }

  disk {
    datastore_id = var.storage
    interface    = "sata0"
    size         = var.disk_size
    file_format  = "raw"
    cache        = "writeback"
    discard      = "on"
    ssd          = true
  }

  cdrom {
    file_id   = var.boot_from_iso ? var.windows_iso_file_id : proxmox_virtual_environment_download_file.virtio_win_iso.id
    interface = "ide2"
  }

  network_device {
    bridge = var.network_bridge
    model  = var.network_model
  }

  vga {
    type   = "std"
    memory = 128
  }

  boot_order = var.boot_from_iso ? ["ide2", "sata0"] : ["sata0", "ide2"]

  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}
