module "mariadb_lxc" {
  source = "../../../modules/lxc-base"

  proxmox_node      = var.proxmox_node
  hostname          = "mariadb"
  lxc_template      = var.lxc_template
  lxc_root_password = var.lxc_root_password
  ssh_public_key    = var.ssh_public_key
  cores             = 2
  memory            = 1024
  rootfs_size       = 16
  ip_address        = var.mariadb_ip
  gateway           = var.gateway
  network_bridge    = var.network_bridge
  storage           = var.storage
  nesting           = true
}

# Pass 2: database and user provisioning (requires MariaDB to be running)
# Set provision_databases = true after running Ansible to deploy MariaDB.

resource "mysql_database" "app_dbs" {
  for_each = var.provision_databases ? { for db in var.databases : db.name => db } : {}
  name     = each.value.name
}

resource "mysql_user" "app_users" {
  for_each           = var.provision_databases ? { for db in var.databases : db.name => db } : {}
  user               = each.value.user
  host               = "%"
  plaintext_password = each.value.password
}

resource "mysql_grant" "app_grants" {
  for_each   = var.provision_databases ? { for db in var.databases : db.name => db } : {}
  user       = mysql_user.app_users[each.key].user
  host       = "%"
  database   = mysql_database.app_dbs[each.key].name
  privileges = ["ALL"]

  depends_on = [mysql_database.app_dbs, mysql_user.app_users]
}
