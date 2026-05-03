output "public_ip" {
  description = "Load balancer public IP address."
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "backend_pool_id" {
  description = "Backend address pool ID for compute module association."
  value       = azurerm_lb_backend_address_pool.bpe_pool.id
}

output "lb_id" {
  description = "Load balancer ID."
  value       = azurerm_lb.cluster_lb.id
}
