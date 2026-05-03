locals {
  nodes = {
    for name in var.node_names : name => {
      index = index(var.node_names, name)
      zone  = length(var.zones) > 0 ? var.zones[index(var.node_names, name) % length(var.zones)] : null
    }
  }
}

resource "azurerm_public_ip" "node_pip" {
  for_each = var.enable_public_ip ? local.nodes : {}

  name                = "pip-${var.project}-${each.key}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zone != null ? [each.value.zone] : []
  tags                = var.tags
}
