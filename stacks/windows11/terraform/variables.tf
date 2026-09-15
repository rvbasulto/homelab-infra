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
  description = "Proxmox node where the Windows VM will be created"
  type        = string
  default     = "pve03"
}

variable "hostname" {
  description = "VM name in Proxmox"
  type        = string
  default     = "windows11"
}

variable "vm_id" {
  description = "Explicit VMID. Leave null to let Proxmox assign the next free one"
  type        = number
  default     = null
}

variable "cores" {
  description = "Number of vCPU cores"
  type        = number
  default     = 4
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "Emulated CPU type"
  type        = string
  default     = "host"
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 80
}

variable "storage" {
  description = "Proxmox storage pool for VM disks, EFI, and TPM state"
  type        = string
  default     = "local-lvm"
}

variable "windows_iso_file_id" {
  description = "Storage-qualified file ID for the Windows 11 ISO uploaded to Proxmox (e.g. local:iso/Win11_25H2_English_x64_v2.iso)"
  type        = string
}

variable "virtio_iso_file_id" {
  description = "Storage-qualified file ID for the VirtIO ISO uploaded to Proxmox (e.g. local:iso/virtio-win.iso)"
  type        = string
  default     = "local:iso/virtio-win.iso"
}

variable "boot_from_iso" {
  description = "true while installing Windows from ISO; set false after installation to boot from disk and mount VirtIO ISO"
  type        = bool
  default     = true
}

variable "network_bridge" {
  description = "Proxmox Linux bridge for the VM"
  type        = string
  default     = "vmbr0"
}

variable "network_model" {
  description = "NIC model. e1000 works during Windows install; switch to virtio after installing VirtIO drivers if desired"
  type        = string
  default     = "e1000"
}

variable "qemu_agent_enabled" {
  description = "Enable after installing qemu-ga from the VirtIO guest tools ISO"
  type        = bool
  default     = false
}

variable "on_boot" {
  description = "Start VM automatically when Proxmox boots"
  type        = bool
  default     = false
}

variable "started" {
  description = "Start VM after Terraform creates it"
  type        = bool
  default     = true
}

variable "tags" {
  description = "List of tags to apply to the VM"
  type        = list(string)
  default     = ["windows", "windows11"]
}
