# homelab-infra

Monorepo de infraestructura para el homelab. Gestiona LXCs en Proxmox con Terraform (HCP Terraform) y los configura con Ansible.

## Estructura

```
homelab-infra/
├── modules/
│   └── lxc-base/          # Módulo reutilizable: LXC unprivileged + Docker en Proxmox
├── stacks/
│   ├── database/          # MariaDB 11 en Docker (LXC en pve04 — 192.168.1.60)
│   ├── media/             # Nextcloud en Docker (LXC en pve04 — 192.168.1.65)
│   ├── dns/               # Placeholder — Technitium DNS (futuro)
│   └── k3s/               # Placeholder — clúster K3s (futuro)
└── ansible/
    └── roles/
        ├── docker/        # Instala Docker Engine + Compose plugin
        ├── mariadb/       # Despliega MariaDB vía docker-compose
        └── nextcloud/     # Despliega Nextcloud:apache vía docker-compose
```

Cada stack tiene su propio directorio `terraform/` y `ansible/`. Los roles de Ansible son compartidos y se referencian desde cada stack vía `roles_path` en `ansible.cfg`.

## Proveedores y herramientas

| Herramienta | Versión |
|---|---|
| Terraform | >= 1.5 |
| telmate/proxmox | 3.0.2-rc04 |
| petoju/mysql | ~> 3.0 |
| Ansible | >= 2.14 |
| community.docker | >= 3.0 |
| community.sops | >= 1.6 |

## Prerequisitos

### 1. Proxmox (pve04)

- Descargar template Ubuntu 25.04: Proxmox UI → pve04 → local → CT Templates
- API token con permisos `VM.Allocate`, `VM.Config.*`, `Datastore.AllocateSpace`:
  ```
  pveum user add terraform@pve
  pveum aclmod / -user terraform@pve -role PVEVMAdmin
  pveum user token add terraform@pve terraform
  ```
- Para el stack `media`, ajustar ownership del disco antes del primer apply:
  ```bash
  chown -R 100000:100000 /mnt/pve/disk2t
  ```

### 2. HCP Terraform

Cada stack tiene su propio workspace en la organización `rvbasulto-homelab`. Los workspaces están conectados a este repo vía VCS (GitHub), con el directorio de trabajo configurado en cada workspace:

| Workspace | Working Directory |
|---|---|
| `homelab-database` | `stacks/database/terraform` |
| `homelab-media` | `stacks/media/terraform` |

Variables sensibles configuradas directamente en cada workspace (marcadas como *Sensitive*):

| Variable | Workspaces |
|---|---|
| `proxmox_api_token_secret` | database, media |
| `lxc_root_password` | database, media |
| `ssh_public_key` | database, media |
| `mariadb_root_password` | database (Pass 2) |

Variables no sensibles en `terraform.tfvars` (gitignored para desarrollo local) o también en el workspace.

### 3. Secrets — SOPS + age

Los `group_vars/all.yml` de Ansible están cifrados con [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age). Los archivos cifrados están comprometidos en el repo y son seguros.

**Setup inicial:**
```bash
# Instalar herramientas
apt install age sops

# La clave privada debe estar en:
~/.config/sops/age/keys.txt
```

**Editar variables de un stack:**
```bash
sops stacks/database/ansible/group_vars/all.yml
```

**Crear un all.yml nuevo desde el ejemplo:**
```bash
cp stacks/<stack>/ansible/group_vars/all.yml.example stacks/<stack>/ansible/group_vars/all.yml
# editar con valores reales
sops --encrypt --in-place stacks/<stack>/ansible/group_vars/all.yml
```

## Orden de ejecución

### Stack database

```bash
# Los planes se disparan automáticamente al hacer push.
# Para aplicar: HCP Terraform UI → homelab-database → Confirm & Apply

# Luego correr Ansible (Pass 1 — instala Docker y MariaDB):
cd stacks/database/ansible
ansible-playbook site.yml

# Pass 2 — crear base de datos nextcloud en MariaDB:
# 1. Agregar en HCP Terraform workspace: provision_databases=true, databases=[...]
# 2. Confirmar apply desde la UI
```

### Stack media

```bash
# Prerequisito: Pass 2 del stack database completado.

# Apply desde HCP Terraform UI → homelab-media → Confirm & Apply

# Luego correr Ansible:
cd stacks/media/ansible
ansible-playbook site.yml
```

## Verificación

```bash
# Conectividad SSH a los LXCs
ansible -m ping database   # desde stacks/database/ansible
ansible -m ping media      # desde stacks/media/ansible

# Containers corriendo
ssh root@192.168.1.60 docker ps
ssh root@192.168.1.65 docker ps

# MariaDB sano
ssh root@192.168.1.60 "docker exec mariadb mysqladmin ping -uroot -p"

# Nextcloud respondiendo
curl http://192.168.1.65:8080/status.php
```
