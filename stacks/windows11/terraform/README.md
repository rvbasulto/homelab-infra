# Windows 11 VM

This stack creates a Windows 11 VM on Proxmox with UEFI, TPM 2.0, and the Microsoft Secure Boot keys required by the Windows 11 installer.

The bpg/proxmox provider version used by this repo supports only one CD-ROM device per VM. During installation, the CD-ROM mounts the Windows ISO. After Windows is installed, set `boot_from_iso = false` and apply again; Terraform will boot from disk and mount the VirtIO driver ISO.

## ISO files

Download the Windows 11 ISO from Microsoft:

https://www.microsoft.com/en-us/software-download/windows11

Upload it to Proxmox storage `local` on node `pve03` under ISO Images. The Terraform variable must match the Proxmox file ID, for example:

```hcl
proxmox_node         = "pve03"
windows_iso_file_id = "local:iso/Win11_25H2_English_x64_v2.iso"
```

Later, upload the stable VirtIO ISO manually to Proxmox storage `local` on node `pve03`:

https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

## Install flow

1. Create Terraform Cloud workspace `homelab-windows11`.
2. Define the Proxmox variables in the workspace.
3. Run `terraform apply` with `boot_from_iso = true`.
4. Open the Proxmox console and install Windows 11.
5. Upload `virtio-win.iso` to `local` on `pve03`.
6. After installation, set `boot_from_iso = false` and apply again.
7. In Windows, open the VirtIO CD and run `virtio-win-guest-tools.exe`.
8. Set `qemu_agent_enabled = true` and apply once more.
