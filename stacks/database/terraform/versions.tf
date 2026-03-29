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
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }
}
