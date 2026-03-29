provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
  pm_timeout          = var.proxmox_api_timeout
}

provider "mysql" {
  endpoint = "${var.mariadb_ip}:${var.mariadb_port}"
  username = "root"
  password = var.mariadb_root_password
}
