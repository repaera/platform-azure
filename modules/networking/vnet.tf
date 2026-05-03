resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-core"
  address_space       = var.vnet_address_space
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet_nodes" {
  name                 = "snet-k3s-nodes"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}
