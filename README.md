# homelab-infra

Infrastructure monorepo for the homelab. Manages LXC containers and VMs on Proxmox with Terraform (HCP Terraform) and configures them with Ansible.

## Structure

```
homelab-infra/
├── modules/
│   ├── lxc-base/          # Reusable module: unprivileged LXC on Proxmox (bpg/proxmox)
│   └── vm-base/           # Reusable module: full VM on Proxmox (bpg/proxmox)
├── stacks/
│   ├── agent/             # HCP Terraform Agent — LXC on pve04 (192.168.1.50) [bootstrap]
│   ├── database/          # MariaDB 11 — LXC on pve04 (192.168.1.60)
│   ├── nextcloud/         # Nextcloud — LXC on pve04 (192.168.1.65)
│   ├── plex/              # Plex Media Server — LXC on pve04 (192.168.1.70)
│   └── k3s/               # k3s cluster — VMs on pve/pve02/pve03
│       ├── terraform/     # Provisions VMs via vm-base module
│       ├── ansible/       # Installs k3s on the VMs
│       └── manifests/     # Traefik IngressRoutes for all homelab services
└── ansible/
    └── roles/
        ├── docker/        # Installs Docker Engine + Compose plugin
        ├── tfc-agent/     # Deploys the HCP Terraform Agent via docker-compose
        ├── mariadb/       # Deploys MariaDB via docker-compose
        ├── nextcloud/     # Deploys Nextcloud:apache via docker-compose
        ├── plex/          # Deploys Plex Media Server via docker-compose (linuxserver)
        ├── k3s-common/    # Prepares nodes for k3s (swap, kernel modules, sysctl)
        ├── k3s-server/    # Installs k3s server
        └── k3s-agent/     # Joins k3s agent nodes to the cluster
```

Each stack has its own `terraform/` and `ansible/` directories. Ansible roles are shared and referenced from each stack via `roles_path` in `ansible.cfg`.

## Infrastructure overview

| Stack | Type | Node(s) | IP | VMID | TFC Workspace |
|---|---|---|---|---|---|
| agent | LXC | pve04 | 192.168.1.50 | 106 | homelab-agent |
| database | LXC | pve04 | 192.168.1.60 | 107 | homelab-database |
| nextcloud | LXC | pve04 | 192.168.1.65 | 108 | homelab-nextcloud |
| plex | LXC | pve04 | 192.168.1.70 | — | homelab-plex |
| k3s-server-01 | VM | pve | 192.168.1.97 | 102 | homelab-k3s |
| k3s-agent-01 | VM | pve02 | 192.168.1.80 | 101 | homelab-k3s |
| k3s-agent-02 | VM | pve03 | 192.168.1.157 | 100 | homelab-k3s |

### Proxmox cluster nodes

| Node | IP | Role |
|---|---|---|
| pve | 192.168.1.90 | Cluster API entry point, k3s-server-01 |
| pve02 | 192.168.1.91 | k3s-agent-01 |
| pve03 | 192.168.1.92 | k3s-agent-02 |
| pve04 | 192.168.1.93 | All LXC containers |

`proxmox_api_url` always points to `192.168.1.90` (cluster API). SSH/Ansible targets individual node IPs.

## Providers and tools

| Tool | Version |
|---|---|
| Terraform | >= 1.6 |
| bpg/proxmox | ~> 0.66 |
| petoju/mysql | ~> 3.0 |
| Ansible | >= 2.14 |
| community.docker | >= 3.0 |
| community.sops | >= 1.6 |

## OS templates

| Type | Template | Notes |
|---|---|---|
| LXC | Ubuntu 22.04 (`ubuntu-22.04-standard_22.04-1_amd64.tar.zst`) | ifupdown networking, compatible with unprivileged LXC |
| VM | Ubuntu 24.04 cloud-init (VMID 9000, node pve) | Used by k3s nodes |

> Ubuntu 25.04 is **not used** for LXCs — it has a systemd-networkd/CREDENTIALS bug in unprivileged containers that leaves eth0 DOWN.

## Prerequisites

### 1. Proxmox

- Download Ubuntu 22.04 LXC template on pve04:
  ```bash
  pveam update && pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
  ```
- Ubuntu 24.04 cloud-init VM template (VMID 9000) must exist on pve for k3s.
- API token with sufficient permissions:
  ```
  pveum user add terraform@pve
  pveum aclmod / -user terraform@pve -role PVEVMAdmin
  pveum user token add terraform@pve terraform
  ```

### 2. HCP Terraform

Organization: `rvbasulto-homelab`. One workspace per stack, all using Agent execution mode (except agent stack which uses Local for bootstrap).

| Workspace | Working Directory | Execution Mode | VCS trigger path |
|---|---|---|---|
| `homelab-agent` | `stacks/agent/terraform` | Local | — |
| `homelab-database` | `stacks/database/terraform` | Agent | `stacks/database/terraform/**/*` |
| `homelab-nextcloud` | `stacks/nextcloud/terraform` | Agent | `stacks/nextcloud/terraform/**/*` |
| `homelab-plex` | `stacks/plex/terraform` | Agent | `stacks/plex/terraform/**/*` |
| `homelab-k3s` | `stacks/k3s/terraform` | Agent | `stacks/k3s/terraform/**/*` |

> **Important:** All workspaces must use **Agent** execution mode (not Remote). Remote mode runs from Hashicorp's cloud and cannot reach the internal 192.168.1.x network.

> **VCS trigger:** use Patterns syntax (not Prefixes) and include `modules/**/*` as an additional trigger path so module changes also trigger plans.

Variables per workspace:

| Variable | Sensitive | agent | database | nextcloud | plex | k3s |
|---|---|---|---|---|---|---|
| `proxmox_api_url` | No | tfvars | ✓ | ✓ | ✓ | ✓ |
| `proxmox_api_token_id` | No | tfvars | ✓ | ✓ | ✓ | ✓ |
| `proxmox_api_token_secret` | Yes | tfvars | ✓ | ✓ | ✓ | ✓ |
| `lxc_root_password` | Yes | tfvars | ✓ | ✓ | ✓ | — |
| `ssh_public_key` | Yes | tfvars | ✓ | ✓ | ✓ | ✓ |
| `mariadb_root_password` | Yes | — | ✓ | — | — | — |
| `provision_databases` | No | — | ✓ (`true`) | — | — | — |
| `template_vm_id` | No | — | — | — | — | ✓ (`9000`) |
| `template_node` | No | — | — | — | — | ✓ (`pve`) |

> **Important:** All variables must use category `terraform`, not `env`.

### 3. Secrets — SOPS + age

Ansible `group_vars/all.yml` files are encrypted with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).

```bash
# Install
apt install age sops

# Private key location
~/.config/sops/age/keys.txt

# Edit an existing encrypted file
sops stacks/database/ansible/group_vars/all.yml

# Create from example
cp stacks/<stack>/ansible/group_vars/all.yml.example stacks/<stack>/ansible/group_vars/all.yml
# fill in values, then encrypt
sops --encrypt --in-place stacks/<stack>/ansible/group_vars/all.yml
```

> Use `community.sops.load_vars` as a `pre_tasks` entry in `site.yml` — the `community.sops.sops` vars plugin does not reliably decrypt group_vars files.

## Execution order

### 0. Agent stack (bootstrap — run once)

```bash
# 1. Create Agent Pool in HCP Terraform:
#    Settings → Agent Pools → Create agent pool → New Token → copy token

# 2. Prepare Ansible secrets (SOPS)
cp stacks/agent/ansible/group_vars/all.yml.example stacks/agent/ansible/group_vars/all.yml
# edit all.yml with the real agent token
sops --encrypt --in-place stacks/agent/ansible/group_vars/all.yml

# 3. Prepare terraform.tfvars (gitignored — only for this bootstrap)
cp stacks/agent/terraform/terraform.tfvars.example stacks/agent/terraform/terraform.tfvars
# edit with real Proxmox credentials

# 4. Create the LXC
cd stacks/agent/terraform && terraform init && terraform apply

# 5. Install Docker + tfc-agent
cd ../ansible && ansible-playbook site.yml

# 6. Verify agent appears in HCP Terraform:
#    Settings → Agent Pools → homelab → Agents → "homelab-pve04" (status: idle)

# 7. Configure all other workspaces:
#    Settings → General → Execution Mode → Agent → select pool
#    Settings → General → Working Directory → stacks/<stack>/terraform
#    Settings → Version Control → connect GitHub repo
#    Settings → Version Control → Automatic Run Triggering →
#      Only trigger when files in specified paths change (Patterns syntax)
```

### 1. Database stack

```bash
# Push triggers plan automatically via VCS.
# Apply: HCP Terraform UI → homelab-database → Confirm & Apply

# Pass 1 — install Docker + MariaDB
cd stacks/database/ansible && ansible-playbook site.yml

# Pass 2 — create databases/users (set provision_databases=true in TFC first)
# Apply from HCP Terraform UI → homelab-database → Confirm & Apply
```

### 2. Nextcloud stack

```bash
# Prerequisite: database stack Pass 2 complete.

# Apply: HCP Terraform UI → homelab-nextcloud → Confirm & Apply

# Install Docker + Nextcloud (also configures bind mount on pve04)
cd stacks/nextcloud/ansible && ansible-playbook site.yml

# Nextcloud: http://192.168.1.65:8080  |  https://cloud.home.lab
```

> **Bind mount:** The Proxmox API rejects bind mounts for API tokens (HTTP 403). The Ansible playbook configures them by editing `/etc/pve/lxc/<vmid>.conf` directly on pve04 and doing `pct stop/start`. This is why `mount_point` is in `lifecycle.ignore_changes` in `lxc-base`.

### 3. Plex stack

```bash
# Apply: HCP Terraform UI → homelab-plex → Confirm & Apply

# Install Docker + Plex (also configures bind mount on pve04)
cd stacks/plex/ansible && ansible-playbook site.yml

# Plex: http://192.168.1.70:32400/web
# Add libraries via UI: /movies and /tv
```

### 4. k3s stack

```bash
# Apply: HCP Terraform UI → homelab-k3s → Confirm & Apply
# (Creates 3 VMs by cloning Ubuntu 24.04 template)

# Install k3s
cd stacks/k3s/ansible && ansible-playbook site.yml

# Apply Traefik manifests (creates namespace + ingress routes)
kubectl apply -f stacks/k3s/manifests/
```

**Importing existing VMs** (if VMs already exist and need to be brought under Terraform management):
```bash
cd stacks/k3s/terraform

# Create a temporary terraform.tfvars with sensitive values (delete after import)
cat > terraform.tfvars << 'EOF'
proxmox_api_token_secret = "..."
ssh_public_key           = "..."
EOF

terraform init
terraform import 'module.k3s_vms["k3s-server-01"].proxmox_virtual_environment_vm.this' pve/102
terraform import 'module.k3s_vms["k3s-agent-01"].proxmox_virtual_environment_vm.this'  pve02/101
terraform import 'module.k3s_vms["k3s-agent-02"].proxmox_virtual_environment_vm.this'  pve03/100

rm terraform.tfvars
terraform plan  # should show No changes
```

## Traefik ingress (k3s)

All homelab services are exposed via Traefik running in k3s. External services use the pattern: `Service` (no ClusterIP) + `Endpoints` (manual IP) + `IngressRoute` (Traefik).

| Domain | Backend | Manifest |
|---|---|---|
| `traefik.home.lab` | Traefik dashboard :9000 | `traefik-ingress-internal.yaml` |
| `cloud.home.lab` | Nextcloud 192.168.1.65:8080 | `nextcloud-ingress.yaml` |
| `plex.home.lab` | Plex 192.168.1.70:32400 | `plex-ingress.yaml` |
| `proxmox.home.lab` | Proxmox 192.168.1.90:8006 | `proxmox-ingress.yaml` |
| `dns.home.lab` | Technitium 192.168.1.53:5380 | `technitium-ingress.yaml` |

## Verification

```bash
# LXC connectivity
ssh root@192.168.1.50 docker ps   # agent
ssh root@192.168.1.60 docker ps   # database
ssh root@192.168.1.65 docker ps   # nextcloud
ssh root@192.168.1.70 docker ps   # plex

# MariaDB healthy
ssh root@192.168.1.60 "docker exec mariadb mysqladmin ping -uroot -p"

# Nextcloud responding
curl http://192.168.1.65:8080/status.php

# Plex responding
curl http://192.168.1.70:32400/identity

# k3s cluster healthy
ssh ubuntu@192.168.1.97 "kubectl get nodes"
```

## Known issues and workarounds

| Issue | Workaround |
|---|---|
| Proxmox API rejects bind mounts for API tokens (HTTP 403) | Ansible edits `/etc/pve/lxc/<vmid>.conf` directly on pve04 + `pct stop/start` |
| bpg detects `operating_system` drift after LXC is running | `operating_system` in `lifecycle.ignore_changes` in `lxc-base` — template only applies at creation |
| `community.sops.sops` vars plugin doesn't reliably decrypt group_vars | Use `community.sops.load_vars` as `pre_tasks` in `site.yml` |
| `docker_compose_v2` handler: `restarted: true` is unsupported | Use `state: restarted` instead |
| MariaDB root only allows localhost by default | Set `MARIADB_ROOT_HOST: "%"` in docker-compose (only takes effect on empty data dir) |
| `terraform import` runs locally even with TFC backend | Create a local `terraform.tfvars` with sensitive values, run import, then delete it |
| TFC workspace execution mode set to Remote instead of Agent | Remote mode can't reach 192.168.1.x — always set to Agent |
| k3s `occ files:scan` gets stuck with lock in DB | Clear with: `docker exec mariadb mariadb -u root -p<pass> nextcloud -e 'DELETE FROM oc_file_locks WHERE 1;'` |
