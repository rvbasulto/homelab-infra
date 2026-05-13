terraform {
  required_version = ">= 1.5"

  cloud {
    organization = "rvbasulto-homelab"
    workspaces {
      name = "homelab-nextcloud"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}
