locals {
  k3s_nodes      = { for node in var.k3s_nodes : node.name => node }
  network_prefix = split("/", var.network_cidr)[1]
}

module "k3s_vms" {
  source   = "../../../modules/vm-base"
  for_each = local.k3s_nodes

  proxmox_node   = each.value.target_node
  hostname       = each.value.name
  template_vm_id = var.template_vm_id
  template_node  = var.template_node

  cores   = var.vm_cores
  sockets = var.vm_sockets
  memory  = var.vm_memory_mb
  disk_size = var.vm_disk_gb
  storage = var.vm_storage

  network_bridge = var.vm_bridge
  ip_address     = each.value.ip
  network_prefix = local.network_prefix
  gateway        = var.network_gateway
  nameserver     = var.dns_server
  dns_search     = var.dns_search

  vm_user        = var.vm_user
  ssh_public_key = var.ssh_public_key

  tags = ["k3s", each.value.role]
}
