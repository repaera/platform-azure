resource "azurerm_mysql_flexible_database" "db" {
  for_each = toset(var.databases)

  name                = each.value
  resource_group_name = var.resource_group.name
  server_name         = azurerm_mysql_flexible_server.server.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
