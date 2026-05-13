variable "proxmox_node" {
  description = "Proxmox node name where the VM will be created."
  type        = string
}

variable "hostname" {
  description = "VM name in Proxmox."
  type        = string
}

variable "template_vm_id" {
  description = "VMID of the Proxmox VM template to clone."
  type        = number
}

variable "template_node" {
  description = "Proxmox node where the template lives. Defaults to proxmox_node if not set."
  type        = string
  default     = null
}

variable "cores" {
  description = "Number of vCPU cores."
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets."
  type        = number
  default     = 1
}

variable "memory" {
  description = "RAM in MB."
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "storage" {
  description = "Proxmox storage pool for the disk and cloud-init drive."
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge."
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IPv4 address (without prefix, e.g. 192.168.1.97)."
  type        = string
}

variable "network_prefix" {
  description = "Network prefix length (e.g. 24 for /24)."
  type        = string
  default     = "24"
}

variable "gateway" {
  description = "Default IPv4 gateway."
  type        = string
}

variable "nameserver" {
  description = "DNS server IP."
  type        = string
  default     = "192.168.1.1"
}

variable "dns_search" {
  description = "DNS search domain."
  type        = string
  default     = ""
}

variable "vm_user" {
  description = "Cloud-init username."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init."
  type        = string
}

variable "tags" {
  description = "List of tags to apply to the VM."
  type        = list(string)
  default     = []
}
