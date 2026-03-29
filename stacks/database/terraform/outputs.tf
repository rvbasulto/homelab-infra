output "mariadb_hostname" {
  description = "Hostname of the MariaDB LXC container"
  value       = module.mariadb_lxc.hostname
}

output "mariadb_ip" {
  description = "IP address of the MariaDB LXC container"
  value       = module.mariadb_lxc.ip_address
}

output "mariadb_lxc_id" {
  description = "Proxmox VMID of the MariaDB LXC container"
  value       = module.mariadb_lxc.lxc_id
}

output "provisioned_databases" {
  description = "Names of databases provisioned in Pass 2"
  value       = [for db in mysql_database.app_dbs : db.name]
}
