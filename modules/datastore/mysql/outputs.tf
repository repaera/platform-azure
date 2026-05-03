output "fqdn" {
  description = "MySQL server FQDN."
  value       = azurerm_mysql_flexible_server.server.fqdn
}

output "admin_username" {
  description = "Admin username."
  value       = azurerm_mysql_flexible_server.server.administrator_login
}

output "connection_string" {
  description = "Connection string template."
  value       = "mysql2://${azurerm_mysql_flexible_server.server.administrator_login}:${var.admin_password}@${azurerm_mysql_flexible_server.server.fqdn}:3306?ssl_mode=require"
  sensitive   = true
}
