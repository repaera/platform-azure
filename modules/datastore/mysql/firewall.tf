resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  count = length(var.allowed_cidrs) > 0 ? 1 : 0

  name                = "AllowAzureServices"
  resource_group_name = var.resource_group.name
  server_name         = azurerm_mysql_flexible_server.server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "extra" {
  for_each = toset(var.allowed_cidrs)

  name                = "Allow-${replace(each.value, "/", "-")}"
  resource_group_name = var.resource_group.name
  server_name         = azurerm_mysql_flexible_server.server.name
  start_ip_address    = cidrhost(each.value, 0)
  end_ip_address      = cidrhost(each.value, -2)
}
