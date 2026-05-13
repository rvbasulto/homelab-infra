terraform {
  required_version = ">= 1.6"

  cloud {
    organization = "rvbasulto-homelab"
    workspaces {
      name = "homelab-k3s"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}
