terraform {
  required_version = ">= 1.5"

  cloud {
    organization = "rvbasulto-homelab"
    workspaces {
      name = "homelab-database"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }
}
