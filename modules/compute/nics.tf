resource "azurerm_network_interface" "nic" {
  for_each = local.nodes

  name                = "nic-${var.project}-${each.key}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.node_pip[each.key].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  for_each = local.nodes

  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = var.nsg_id
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_assoc" {
  for_each = var.associate_lb ? local.nodes : {}

  network_interface_id    = azurerm_network_interface.nic[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.lb_pool_id
}
