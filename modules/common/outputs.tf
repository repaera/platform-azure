output "resource_group" {
  description = "The created resource group object."
  value       = azurerm_resource_group.rg
}

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "Azure region."
  value       = azurerm_resource_group.rg.location
}

output "tags" {
  description = "Merged tags."
  value       = local.tags
}
