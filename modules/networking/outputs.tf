output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  description = "Node subnet ID."
  value       = azurerm_subnet.subnet_nodes.id
}

output "nsg_id" {
  description = "Network security group ID."
  value       = azurerm_network_security_group.nsg.id
}

output "subnet_prefix" {
  description = "Subnet CIDR for NSG rules."
  value       = var.subnet_address_prefixes[0]
}
