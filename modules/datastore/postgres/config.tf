# Enable pgvector extension via server configuration
resource "azurerm_postgresql_flexible_server_configuration" "pgvector" {
  count = var.enable_pgvector ? 1 : 0

  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.server.id
  value     = "VECTOR"
}

# Enable pgbouncer
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer" {
  count = var.enable_pgbouncer ? 1 : 0

  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.server.id
  value     = "true"
}

# Create databases
resource "azurerm_postgresql_flexible_server_database" "db" {
  for_each = toset(var.databases)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.server.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
