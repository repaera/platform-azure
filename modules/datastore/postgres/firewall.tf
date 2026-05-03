# Allow Azure services (required for the server to function properly)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  count = length(var.allowed_cidrs) > 0 ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Additional firewall rules for specific CIDRs
resource "azurerm_postgresql_flexible_server_firewall_rule" "extra" {
  for_each = toset(var.allowed_cidrs)

  name             = "Allow-${replace(each.value, "/", "-")}"
  server_id        = azurerm_postgresql_flexible_server.server.id
  start_ip_address = cidrhost(each.value, 0)
  end_ip_address   = cidrhost(each.value, -2)
}
