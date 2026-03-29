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

variable "proxmox_api_timeout" {
  description = "Proxmox API timeout in seconds"
  type        = number
  default     = 600
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

variable "mariadb_ip" {
  description = "Static IP address for the MariaDB LXC container"
  type        = string
  default     = "192.168.1.60"
}

variable "mariadb_port" {
  description = "MariaDB port"
  type        = number
  default     = 3306
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

variable "mariadb_root_password" {
  description = "MariaDB root password (used by mysql provider in Pass 2)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "provision_databases" {
  description = "Pass 2 gate: set to true after MariaDB is running to create databases and users"
  type        = bool
  default     = false
}

variable "databases" {
  description = "List of databases to provision in Pass 2"
  type = list(object({
    name     = string
    user     = string
    password = string
  }))
  default = []
}
