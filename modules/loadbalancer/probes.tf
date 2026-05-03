# Probe for HTTP traffic (Traefik on port 80)
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.cluster_lb.id
  name            = "probe-http-80"
  port            = 80
  protocol        = "Tcp"
}

# Probe for HTTPS traffic (Traefik on port 443)
resource "azurerm_lb_probe" "https_probe" {
  loadbalancer_id = azurerm_lb.cluster_lb.id
  name            = "probe-https-443"
  port            = 443
  protocol        = "Tcp"
}

# Probe for K8s API (port 6443)
resource "azurerm_lb_probe" "api_probe" {
  loadbalancer_id = azurerm_lb.cluster_lb.id
  name            = "probe-k8s-api-6443"
  port            = 6443
  protocol        = "Tcp"
}
