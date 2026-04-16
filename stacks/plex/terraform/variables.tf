variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g. terraform@pve!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification for self-signed certificates"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve04"
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

variable "plex_ip" {
  description = "Static IP address for the Plex LXC container"
  type        = string
  default     = "192.168.1.70"
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
