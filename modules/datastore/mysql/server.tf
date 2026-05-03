resource "azurerm_mysql_flexible_server" "server" {
  name                = var.server_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  administrator_login = var.admin_username
  administrator_password = var.admin_password
  sku_name             = var.sku_name
  storage {
    size_gb = var.storage_mb / 1024
  }
  tags = var.tags
}
