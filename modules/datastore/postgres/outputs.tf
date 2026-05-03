output "fqdn" {
  description = "PostgreSQL server FQDN."
  value       = azurerm_postgresql_flexible_server.server.fqdn
}

output "admin_username" {
  description = "Admin username."
  value       = azurerm_postgresql_flexible_server.server.administrator_login
}

output "connection_string" {
  description = "Connection string template."
  value       = "postgresql://${azurerm_postgresql_flexible_server.server.administrator_login}:${var.admin_password}@${azurerm_postgresql_flexible_server.server.fqdn}:5432/postgres?sslmode=require"
  sensitive   = true
}

output "pgbouncer_connection_string" {
  description = "PgBouncer connection string template (port 6432)."
  value       = "postgresql://${azurerm_postgresql_flexible_server.server.administrator_login}:${var.admin_password}@${azurerm_postgresql_flexible_server.server.fqdn}:6432/postgres?sslmode=require"
  sensitive   = true
}
