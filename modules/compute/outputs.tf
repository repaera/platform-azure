output "public_ips" {
  description = "Map of node name -> public IP address."
  value       = var.enable_public_ip ? { for k, v in azurerm_public_ip.node_pip : k => v.ip_address } : {}
}

output "private_ips" {
  description = "Map of node name -> private IP address."
  value       = { for k, v in azurerm_network_interface.nic : k => v.private_ip_address }
}

output "node_names" {
  description = "List of node names."
  value       = var.node_names
}

output "first_node_name" {
  description = "First node name for init."
  value       = var.node_names[0]
}

output "first_node_public_ip" {
  description = "Public IP of the first node."
  value       = var.enable_public_ip ? azurerm_public_ip.node_pip[var.node_names[0]].ip_address : ""
}

output "join_node_names" {
  description = "Node names excluding the first."
  value       = slice(var.node_names, 1, length(var.node_names))
}
