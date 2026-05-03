resource "azurerm_public_ip" "lb_pip" {
  name                = "pip-${var.project}-lb"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "cluster_lb" {
  name                = "lb-${var.project}-cluster"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpe_pool" {
  loadbalancer_id = azurerm_lb.cluster_lb.id
  name            = "bpe-k3s-nodes"
}
