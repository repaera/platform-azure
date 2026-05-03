# K8s API rule
resource "azurerm_lb_rule" "rule_api" {
  loadbalancer_id                = azurerm_lb.cluster_lb.id
  name                           = "Rule-K8s-API"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpe_pool.id]
  probe_id                       = azurerm_lb_probe.api_probe.id
}

# HTTP rule
resource "azurerm_lb_rule" "rule_http" {
  loadbalancer_id                = azurerm_lb.cluster_lb.id
  name                           = "Rule-HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpe_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# HTTPS rule — WIRED TO HTTPS PROBE (port 443), NOT HTTP PROBE
resource "azurerm_lb_rule" "rule_https" {
  loadbalancer_id                = azurerm_lb.cluster_lb.id
  name                           = "Rule-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpe_pool.id]
  probe_id                       = azurerm_lb_probe.https_probe.id
}
