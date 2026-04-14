# homelab-infra

Monorepo: Terraform + Ansible for homelab on Proxmox (pve04).

## Structure

```
modules/lxc-base/         # Reusable LXC module (bpg/proxmox)
stacks/
  agent/                  # Bootstrap: creates the TFC agent LXC (local execution)
  database/               # MariaDB LXC + DB/user provisioning
  media/                  # Nextcloud LXC with disk2t bind-mount
ansible/
  roles/
    docker/               # Installs Docker Engine
    mariadb/              # Deploys MariaDB via Docker Compose
    nextcloud/            # Deploys Nextcloud via Docker Compose
    tfc-agent/            # Deploys HCP Terraform Cloud Agent via Docker Compose
```

## Provider

**bpg/proxmox ~> 0.66** (migrated from telmate on 2026-03-30 — telmate did not write netplan config in Ubuntu 25.04).
Template: **Ubuntu 22.04** (22.04 uses ifupdown, compatible with unprivileged LXC; 25.04 has a systemd-networkd/CREDENTIALS bug in LXC).

Provider config in each stack:
```hcl
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure
}
```

## lxc-base module — key variables

- `rootfs_size`: number in GB (e.g. `8`, `16`) — NOT a string
- `mountpoints`: list of `{ mp = string, volume = string }` — bind mounts only
- `nameserver`: use `dns.servers = [var.nameserver]` (not deprecated `server`)
- `nesting`: set to `true` for stacks that run Docker (required for overlayfs in unprivileged LXC). Container must be fully stopped and started (not just rebooted) for this to take effect.

## Stacks

| Stack | TFC Workspace | Node | IP | VMID |
|---|---|---|---|---|
| agent | homelab-agent | pve04 | 192.168.1.50 | — |
| database | homelab-database | pve04 | 192.168.1.60 | — |
| media | homelab-media | pve04 | 192.168.1.65 | — |

## Current status (2026-04-12)

### Agent stack — COMPLETE ✓
- LXC `tfc-agent` running on pve04 (IP 192.168.1.50)
- Docker installed, `hashicorp/tfc-agent` deployed via docker-compose
- Agent online in HCP Terraform org `rvbasulto-homelab`

### Database stack — IN PROGRESS
- Pass 1 (LXC creation) — COMPLETE ✓
- Ansible (Docker + MariaDB) — COMPLETE ✓ (2026-04-12)
- TFC workspace variables configured ✓ (2026-04-13)
- **Next step:** Pass 2 — trigger run in TFC workspace `homelab-database`

#### TFC workspace variables (homelab-database)
| Variable | Sensitive | Notes |
|---|---|---|
| `provision_databases` | no | `true` |
| `mariadb_root_password` | yes | MariaDB root password |
| `databases` | no | `[{name="nextcloud", user="nextcloud", password="..."}]` — visible en UI para facilitar edición futura |
| `proxmox_api_token_secret` | yes | |
| `lxc_root_password` | yes | |
| `ssh_public_key` | yes | optiplex public key |
| `proxmox_api_token_id` | no | `terraform@pve!terraform` |
| `proxmox_api_url` | no | `https://192.168.1.90:8006/api2/json` |

> `databases` se dejó **no sensitive** intencionalmente para poder ver y editar su contenido desde la UI.
> Pendiente: evaluar guardar el valor canónico en `group_vars/all.yml` (SOPS) como fuente de verdad.

### Media stack — PENDING
- Infrastructure not yet applied
- Requires `chown -R 100000:100000 /mnt/pve/disk2t` on pve04 before applying

## Notes

- disk2t bind mount in media: host path `/mnt/pve/disk2t`, container path configurable via `disk2t_container_path`
- Database uses two-pass: Pass 1 creates LXC (provision_databases=false) → Ansible → Pass 2 creates DBs (provision_databases=true)
- Terraform Cloud org: `rvbasulto-homelab`
- Proxmox API: `terraform@pve!terraform` token

## Ansible SOPS setup

The `community.sops.sops` vars plugin does NOT reliably discover group_vars files.
Use `community.sops.load_vars` as a `pre_tasks` entry in each `site.yml` instead:

```yaml
pre_tasks:
  - name: Load SOPS-encrypted variables
    community.sops.load_vars:
      file: "{{ playbook_dir }}/group_vars/all.yml"
```

Also set `vars_plugins_enabled = host_group_vars` in `ansible.cfg` (do not include `community.sops.sops` as a vars plugin).

## Ansible docker_compose_v2 handler

To restart a compose project in a handler, use `state: restarted` — NOT `restarted: true` (unsupported parameter):

```yaml
- name: Restart <service>
  community.docker.docker_compose_v2:
    project_src: "{{ compose_dir }}"
    state: restarted
```
