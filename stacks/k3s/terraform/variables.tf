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

variable "template_vm_id" {
  description = "VMID of the Ubuntu VM template to clone (must exist on template_node)"
  type        = number
}

variable "template_node" {
  description = "Proxmox node where the template lives"
  type        = string
  default     = "pve"
}

variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init"
  type        = string
}

variable "vm_user" {
  description = "Cloud-init username"
  type        = string
  default     = "ubuntu"
}

variable "vm_cores" {
  description = "Number of vCPU cores per VM"
  type        = number
  default     = 2
}

variable "vm_sockets" {
  description = "Number of CPU sockets per VM"
  type        = number
  default     = 1
}

variable "vm_memory_mb" {
  description = "RAM per VM in MB"
  type        = number
  default     = 4096
}

variable "vm_disk_gb" {
  description = "Boot disk size per VM in GB"
  type        = number
  default     = 30
}

variable "vm_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "network_cidr" {
  description = "Network CIDR used to derive the prefix length (e.g. 192.168.1.0/24)"
  type        = string
  default     = "192.168.1.0/24"
}

variable "network_gateway" {
  description = "Default gateway for the VMs"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_server" {
  description = "Primary DNS server"
  type        = string
  default     = "192.168.1.53"
}

variable "dns_search" {
  description = "DNS search domain"
  type        = string
  default     = "home.lab"
}

variable "k3s_nodes" {
  description = "k3s VMs to provision — one entry per node"
  type = list(object({
    name        = string
    target_node = string
    role        = string
    ip          = string
  }))
  default = [
    {
      name        = "k3s-server-01"
      target_node = "pve"
      role        = "server"
      ip          = "192.168.1.97"
    },
    {
      name        = "k3s-agent-01"
      target_node = "pve02"
      role        = "agent"
      ip          = "192.168.1.80"
    },
    {
      name        = "k3s-agent-02"
      target_node = "pve03"
      role        = "agent"
      ip          = "192.168.1.157"
    }
  ]
}
