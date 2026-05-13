# homelab-infra

Monorepo: Terraform + Ansible for homelab on Proxmox (pve04).

## Structure

```
modules/
  lxc-base/               # Reusable LXC module (bpg/proxmox) — for services (Nextcloud, Plex, etc.)
  vm-base/                # Reusable VM module (bpg/proxmox) — for workloads needing a full kernel (k3s)
stacks/
  agent/                  # Bootstrap: creates the TFC agent LXC (local execution)
  database/               # MariaDB LXC + DB/user provisioning
  media/                  # Nextcloud LXC with disk2t bind-mount
  plex/                   # Plex Media Server LXC with disk2t bind-mount
  k3s/                    # 3-node k3s cluster (1 server + 2 agents) across pve/pve02/pve03
    terraform/            # Provisions VMs via vm-base module
    ansible/              # Installs k3s on the VMs
    manifests/            # Traefik IngressRoutes for all homelab services
ansible/
  roles/
    docker/               # Installs Docker Engine
    k3s-agent/            # Joins k3s agent nodes to the cluster
    k3s-common/           # Prepares nodes for k3s (swap, kernel modules, sysctl)
    k3s-server/           # Installs k3s server
    mariadb/              # Deploys MariaDB via Docker Compose
    nextcloud/            # Deploys Nextcloud via Docker Compose
    plex/                 # Deploys Plex Media Server via Docker Compose (linuxserver image)
    tfc-agent/            # Deploys HCP Terraform Cloud Agent via Docker Compose
```

## Proxmox cluster

| Node | IP |
|---|---|
| pve (cluster API entry point) | 192.168.1.90 |
| pve04 (all homelab LXCs run here) | 192.168.1.93 |

`proxmox_api_url` points to `192.168.1.90` (cluster node). SSH to pve04 uses `192.168.1.93`.

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
- `mountpoints`: list of `{ mp = string, volume = string }` — bind mounts only. **Do not use for bind mounts** — see note below.
- `nameserver`: use `dns.servers = [var.nameserver]` (not deprecated `server`)
- `nesting`: set to `true` for stacks that run Docker (required for overlayfs in unprivileged LXC). Container must be fully stopped and started (not just rebooted) for this to take effect.

## Stacks

| Stack | TFC Workspace | Node | IP | VMID |
|---|---|---|---|---|
| agent | homelab-agent | pve04 | 192.168.1.50 | 106 |
| database | homelab-database | pve04 | 192.168.1.60 | 107 |
| media | homelab-media | pve04 | 192.168.1.65 | — |
| plex | homelab-plex | pve04 | 192.168.1.70 | — |
| k3s | homelab-k3s | pve/pve02/pve03 | see below | — |

**k3s nodes:**

| VM | Proxmox node | IP | Role |
|---|---|---|---|
| k3s-server-01 | pve | 192.168.1.97 | server |
| k3s-agent-01 | pve02 | 192.168.1.80 | agent |
| k3s-agent-02 | pve03 | 192.168.1.157 | agent |

## Current status (2026-04-16)

### Agent stack — COMPLETE ✓
- LXC `tfc-agent` running on pve04 (IP 192.168.1.50, VMID 106)
- Docker installed, `hashicorp/tfc-agent` deployed via docker-compose
- Agent online in HCP Terraform org `rvbasulto-homelab`

### Database stack — COMPLETE ✓ (2026-04-13)
- Pass 1 (LXC creation) — COMPLETE ✓
- Ansible (Docker + MariaDB) — COMPLETE ✓
- Pass 2 (databases + users via petoju/mysql) — COMPLETE ✓
- DB: `nextcloud`, user: `nextcloud` created in MariaDB (192.168.1.60, VMID 107)

#### TFC workspace variables (homelab-database)
| Variable | Sensitive | Notes |
|---|---|---|
| `provision_databases` | no | `true` |
| `mariadb_root_password` | yes | MariaDB root password |
| `databases` | no | `[{name="nextcloud", user="nextcloud", password="..."}]` — left non-sensitive intentionally for visibility and ease of editing in the UI |
| `proxmox_api_token_secret` | yes | |
| `lxc_root_password` | yes | |
| `ssh_public_key` | yes | optiplex public key |
| `proxmox_api_token_id` | no | `terraform@pve!terraform` |
| `proxmox_api_url` | no | `https://192.168.1.90:8006/api2/json` |

> TODO: evaluate storing the canonical value of `databases` in `group_vars/all.yml` (SOPS) as source of truth.

### Media stack — COMPLETE ✓ (2026-04-14)
- Terraform apply — COMPLETE ✓ (LXC at 192.168.1.65)
- Ansible (bind mount on pve04 + Docker + Nextcloud) — COMPLETE ✓
- Nextcloud accessible at `http://192.168.1.65:8080` and `https://cloud.home.lab` (via Traefik at 192.168.1.97)
- User `rvbasulto` files migrated from backup ✓

- User `grdelgado` files migrated from backup ✓ (316,789 files, 43,703 folders scanned)

#### TFC workspace variables (homelab-media)
| Variable | Sensitive | Notes |
|---|---|---|
| `proxmox_api_token_secret` | yes | |
| `lxc_root_password` | yes | |
| `ssh_public_key` | yes | optiplex public key |
| `proxmox_api_token_id` | no | `terraform@pve!terraform` |
| `proxmox_api_url` | no | `https://192.168.1.90:8006/api2/json` |

### k3s stack — COMPLETE ✓ (2026-05-12)
- Migrated from `proxmox-k3s-lab` repo into this monorepo
- Terraform — uses `vm-base` module (bpg/proxmox), TFC workspace `homelab-k3s` ✓
- Existing VMs imported via `terraform import` (pve/102, pve02/101, pve03/100) ✓
- `terraform plan` shows No changes ✓
- Ansible roles: k3s-common, k3s-server, k3s-agent ✓
- Traefik manifests in `stacks/k3s/manifests/` ✓

Template: Ubuntu 24.04 cloud-init (VMID 9000, node pve). VMs use Ubuntu 24.04; LXCs use Ubuntu 22.04.

#### vm-base import gotchas
- `terraform import` runs locally even with TFC backend — requires a local `terraform.tfvars` with sensitive vars during import (delete after)
- bpg adds `description = "Managed by Terraform."` on import — add `description` to `lifecycle.ignore_changes`
- `keyboard_layout`, `agent.type`, `operating_system`, `serial_device` must be explicitly declared in vm-base or they show as drift

#### TFC workspace variables (homelab-k3s)
| Variable | Sensitive | Notes |
|---|---|---|
| `proxmox_api_token_secret` | yes | |
| `lxc_root_password` | yes | not used, but kept for consistency |
| `ssh_public_key` | yes | optiplex public key |
| `proxmox_api_token_id` | no | `terraform@pve!terraform` |
| `proxmox_api_url` | no | `https://192.168.1.90:8006/api2/json` |
| `template_vm_id` | no | `9000` (Ubuntu 24.04 cloud-init template on pve) |
| `template_node` | no | `pve` |

#### vm-base vs lxc-base
- `lxc-base` — for services running Docker in LXC (Nextcloud, Plex, MariaDB, agent)
- `vm-base` — for workloads needing a dedicated kernel: k3s nodes, any future VM-based stack

#### Traefik manifests (stacks/k3s/manifests/)
External service pattern: Service (no ClusterIP) + Endpoints (manual IP) + IngressRoute (Traefik).
Apply with: `kubectl apply -f stacks/k3s/manifests/`

| File | Domain | Backend |
|---|---|---|
| traefik-config.yaml | — | Enables Traefik dashboard |
| traefik-ingress-internal.yaml | traefik.home.lab | Traefik dashboard :9000 |
| nextcloud-ingress.yaml | cloud.home.lab | 192.168.1.65:8080 |
| plex-ingress.yaml | plex.home.lab | 192.168.1.70:32400 |
| proxmox-ingress.yaml | proxmox.home.lab | 192.168.1.90:8006 (HTTPS) |
| technitium-ingress.yaml | dns.home.lab | 192.168.1.53:5380 |

### Plex stack — COMPLETE ✓ (2026-04-16)
- Terraform apply — COMPLETE ✓ (LXC at 192.168.1.70)
- Ansible (bind mount on pve04 + Docker + Plex) — COMPLETE ✓
- Plex accessible at `http://192.168.1.70:32400/web`
- Libraries configured: Movies (`/movies`) and TV Shows (`/tv`) from `/mnt/disk2t/plex/media`
- Image: `lscr.io/linuxserver/plex:latest`, `network_mode: host`

> **Note:** TFC workspace execution mode must be set to **Agent** (not Remote). Remote mode runs from Hashicorp's cloud and cannot reach the internal 192.168.1.x network.

#### TFC workspace variables (homelab-plex)
| Variable | Sensitive | Notes |
|---|---|---|
| `proxmox_api_token_secret` | yes | |
| `lxc_root_password` | yes | |
| `ssh_public_key` | yes | optiplex public key |
| `proxmox_api_token_id` | no | `terraform@pve!terraform` |
| `proxmox_api_url` | no | `https://192.168.1.90:8006/api2/json` |

## Notes

- disk2t storage: mounted at `/mnt/disk2t` on pve04 (NOT `/mnt/pve/disk2t`). It is a `dir` type storage in Proxmox with a custom mount path.
- Bind mounts via Proxmox API are restricted to `root@pam` direct sessions — API tokens (even for `root@pam`) are rejected with HTTP 403. Workaround: configure bind mounts via Ansible by editing `/etc/pve/lxc/<vmid>.conf` on pve04 directly and restarting the LXC with `pct stop/start`.
- Database uses two-pass: Pass 1 creates LXC (provision_databases=false) → Ansible → Pass 2 creates DBs (provision_databases=true)
- Terraform Cloud org: `rvbasulto-homelab`
- Proxmox API token: `terraform@pve!terraform`

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

## Bind mounts in Proxmox LXC via Ansible

Proxmox API rejects bind mounts for any API token (HTTP 403), even `root@pam` tokens. Only direct `root@pam` sessions are allowed.

Workaround used in the media stack: Ansible runs a play on pve04 that edits the LXC config file directly:

```yaml
- name: Ensure bind mount is configured in LXC config
  lineinfile:
    path: "/etc/pve/lxc/{{ vmid }}.conf"
    line: "mp0: /mnt/disk2t,mp=/mnt/disk2t"
    regexp: "^mp0:"
    state: present
```

Then stops and starts the LXC (a restart is not sufficient — full stop/start required for mount changes to take effect).

## MariaDB remote access for Terraform provider

The `petoju/mysql` provider connects from the TFC agent (192.168.1.50) to MariaDB remotely. By default MariaDB only allows `root@localhost`. Requires `MARIADB_ROOT_HOST: "%"` in docker-compose:

```yaml
environment:
  MARIADB_ROOT_PASSWORD: "{{ mariadb_root_password }}"
  MARIADB_ROOT_HOST: "%"
```

**Important:** this variable only takes effect on initialization (empty data dir). If the container already existed, clean the data dir and recreate it:
```bash
docker compose -f /opt/mariadb/docker-compose.yml down && rm -rf /opt/mariadb/data/*
```

## Ansible docker_compose_v2 handler

To restart a compose project in a handler, use `state: restarted` — NOT `restarted: true` (unsupported parameter):

```yaml
- name: Restart <service>
  community.docker.docker_compose_v2:
    project_src: "{{ compose_dir }}"
    state: restarted
```
