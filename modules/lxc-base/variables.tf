variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "hostname" {
  description = "Hostname for the LXC container"
  type        = string
}

variable "lxc_template" {
  description = "LXC OS template (must be pre-downloaded on the Proxmox node)"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "lxc_root_password" {
  description = "Root password for the LXC container"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key to inject into root's authorized_keys"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 1024
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 0
}

variable "rootfs_size" {
  description = "Root filesystem size in GB"
  type        = number
  default     = 8
}

variable "ip_address" {
  description = "Static IP address (without CIDR suffix)"
  type        = string
}

variable "gateway" {
  description = "Default gateway for the LXC container"
  type        = string
  default     = "192.168.1.1"
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "storage" {
  description = "Proxmox storage pool for the rootfs"
  type        = string
  default     = "local-lvm"
}

variable "nameserver" {
  description = "DNS server IP for the LXC container"
  type        = string
  default     = "192.168.1.53"
}

variable "nesting" {
  description = "Enable nesting (required for Docker in unprivileged LXC)"
  type        = bool
  default     = false
}

variable "mountpoints" {
  description = "Optional bind-mount list for the LXC container"
  type = list(object({
    mp     = string
    volume = string
  }))
  default = []
}
