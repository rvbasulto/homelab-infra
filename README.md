# homelab-infra

Infrastructure monorepo for the homelab. Manages LXCs on Proxmox with Terraform (HCP Terraform) and configures them with Ansible.

## Structure

```
homelab-infra/
├── modules/
│   └── lxc-base/          # Reusable module: unprivileged LXC + Docker on Proxmox
├── stacks/
│   ├── agent/             # HCP Terraform Agent (LXC on pve04 — 192.168.1.50) [bootstrap]
│   ├── database/          # MariaDB 11 on Docker (LXC on pve04 — 192.168.1.60)
│   ├── media/             # Nextcloud on Docker (LXC on pve04 — 192.168.1.65)
│   ├── dns/               # Placeholder — Technitium DNS (future)
│   └── k3s/               # Placeholder — K3s cluster (future)
└── ansible/
    └── roles/
        ├── docker/        # Installs Docker Engine + Compose plugin
        ├── tfc-agent/     # Deploys the HCP Terraform Agent via docker-compose
        ├── mariadb/       # Deploys MariaDB via docker-compose
        └── nextcloud/     # Deploys Nextcloud:apache via docker-compose
```

Each stack has its own `terraform/` and `ansible/` directories. Ansible roles are shared and referenced from each stack via `roles_path` in `ansible.cfg`.

## Providers and tools

| Tool | Version |
|---|---|
| Terraform | >= 1.5 |
| bpg/proxmox | ~> 0.66 |
| petoju/mysql | ~> 3.0 |
| Ansible | >= 2.14 |
| community.docker | >= 3.0 |
| community.sops | >= 1.6 |

## Prerequisites

### 1. Proxmox (pve04)

- Download Ubuntu 22.04 template: Proxmox UI → pve04 → local → CT Templates
  ```bash
  pveam update && pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
  ```
- API token with `VM.Allocate`, `VM.Config.*`, `Datastore.AllocateSpace` permissions:
  ```
  pveum user add terraform@pve
  pveum aclmod / -user terraform@pve -role PVEVMAdmin
  pveum user token add terraform@pve terraform
  ```
- For the `media` stack, adjust disk ownership before the first apply:
  ```bash
  chown -R 100000:100000 /mnt/pve/disk2t
  ```

### 2. HCP Terraform

Each stack has its own workspace in the `rvbasulto-homelab` organization.

| Workspace | Working Directory | Execution Mode |
|---|---|---|
| `homelab-agent` | `stacks/agent/terraform` | Local (one-time bootstrap) |
| `homelab-database` | `stacks/database/terraform` | Agent |
| `homelab-media` | `stacks/media/terraform` | Agent |

The `database` and `media` workspaces are connected to this repo via VCS (GitHub) and use the Agent Pool from the `agent` stack to run plans inside the homelab network.

Sensitive variables configured directly in each workspace (marked as *Sensitive*):

| Variable | Workspaces |
|---|---|
| `proxmox_api_token_secret` | database, media |
| `lxc_root_password` | database, media |
| `ssh_public_key` | database, media |
| `mariadb_root_password` | database (Pass 2) |

> The `homelab-agent` workspace is the exception: it uses a local `terraform.tfvars` (gitignored) because it runs once in bootstrap mode before the agent exists.

### 3. Secrets — SOPS + age

Ansible `group_vars/all.yml` files are encrypted with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age). Encrypted files are committed to the repo and are safe.

**Initial setup:**
```bash
# Install tools
apt install age sops

# Private key must be at:
~/.config/sops/age/keys.txt
```

**Edit variables for a stack:**
```bash
sops stacks/database/ansible/group_vars/all.yml
```

**Create a new all.yml from the example:**
```bash
cp stacks/<stack>/ansible/group_vars/all.yml.example stacks/<stack>/ansible/group_vars/all.yml
# fill in real values
sops --encrypt --in-place stacks/<stack>/ansible/group_vars/all.yml
```

## Execution order

### 0. Agent stack (bootstrap — run once)

```bash
# 1. Create Agent Pool in HCP Terraform:
#    Settings → Agent Pools → Create agent pool → New Token → copy token

# 2. Prepare Ansible secrets
cp stacks/agent/ansible/group_vars/all.yml.example stacks/agent/ansible/group_vars/all.yml
# edit all.yml with the real token
sops --encrypt --in-place stacks/agent/ansible/group_vars/all.yml

# 3. Prepare terraform.tfvars (gitignored, only for this bootstrap)
cp stacks/agent/terraform/terraform.tfvars.example stacks/agent/terraform/terraform.tfvars
# edit terraform.tfvars with real Proxmox IP and credentials

# 4. Create the LXC
cd stacks/agent/terraform
terraform init && terraform apply

# 5. Install the agent
cd ../ansible
ansible-playbook site.yml

# 6. Verify the agent appears in HCP Terraform:
#    Settings → Agent Pools → homelab → Agents → should show "homelab-pve04"

# 7. Configure database and media workspaces:
#    Settings → General → Execution Mode → Agent → select pool
#    Settings → Version Control → connect GitHub repo
#    Settings → General → Terraform Working Directory → stacks/<stack>/terraform
```

### Database stack

```bash
# Plans trigger automatically on push.
# To apply: HCP Terraform UI → homelab-database → Confirm & Apply

# Then run Ansible (Pass 1 — installs Docker and MariaDB):
cd stacks/database/ansible
ansible-playbook site.yml

# Pass 2 — create nextcloud database in MariaDB:
# 1. Set in HCP Terraform workspace: provision_databases=true, databases=[...]
# 2. Confirm apply from the UI
```

### Media stack

```bash
# Prerequisite: database stack Pass 2 completed.

# Apply from HCP Terraform UI → homelab-media → Confirm & Apply

# Then run Ansible:
cd stacks/media/ansible
ansible-playbook site.yml
```

## Verification

```bash
# SSH connectivity to LXCs
ansible -m ping database   # from stacks/database/ansible
ansible -m ping media      # from stacks/media/ansible

# Running containers
ssh root@192.168.1.60 docker ps
ssh root@192.168.1.65 docker ps

# MariaDB healthy
ssh root@192.168.1.60 "docker exec mariadb mysqladmin ping -uroot -p"

# Nextcloud responding
curl http://192.168.1.65:8080/status.php
```
