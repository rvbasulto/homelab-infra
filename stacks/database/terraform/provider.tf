provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure
}

provider "mysql" {
  endpoint = "${var.mariadb_ip}:${var.mariadb_port}"
  username = "root"
  password = var.mariadb_root_password
}
########