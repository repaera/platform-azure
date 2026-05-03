resource "azurerm_postgresql_flexible_server" "server" {
  name                   = var.server_name
  resource_group_name    = var.resource_group.name
  location               = var.resource_group.location
  version                = "16"
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  tags                   = var.tags

  # High availability disabled for single-node / dev tiers.
  # Enable for production by setting high_availability block via optional override.
}
