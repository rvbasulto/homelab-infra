terraform {
  required_version = ">= 1.5"

  # This workspace intentionally uses Local execution mode.
  # It is the bootstrap stack: runs once from the local machine
  # to create the agent LXC. Once the agent is running,
  # all other workspaces switch to Agent execution mode.
  cloud {
    organization = "rvbasulto-homelab"
    workspaces {
      name = "homelab-agent"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}
