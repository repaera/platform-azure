output "load_balancer_ip" {
  description = "Cluster entry point. Use for DNS, TLS-san, and Traefik."
  value       = module.lb.public_ip
}

output "server_public_ips" {
  description = "Map of server name -> public IP for k3sup init/join."
  value       = module.servers.public_ips
}

output "server_private_ips" {
  description = "Map of server name -> private IP."
  value       = module.servers.private_ips
}

output "agent_public_ips" {
  description = "Map of agent name -> public IP."
  value       = module.agents.public_ips
}

output "agent_private_ips" {
  description = "Map of agent name -> private IP."
  value       = module.agents.private_ips
}

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = module.common.resource_group_name
}


output "k3sup_init_command" {
  description = "Run this first to bootstrap the initial k3s server."
  value = <<-EOT
    k3sup install \
      --ip ${module.servers.first_node_public_ip} \
      --user ${var.admin_username} \
      --tls-san ${module.lb.public_ip} \
      --cluster \
      --k3s-extra-args '--disable traefik'
  EOT
}

output "k3sup_join_commands" {
  description = "Run these to join remaining server nodes."
  value = {
    for name in module.servers.join_node_names :
    name => <<-EOT
      k3sup join \
        --ip ${module.servers.public_ips[name]} \
        --server-ip ${module.servers.first_node_public_ip} \
        --user ${var.admin_username} \
        --server \
        --k3s-extra-args '--disable traefik'
    EOT
  }
}

output "k3sup_agent_commands" {
  description = "Run these to join agent nodes (no --server flag)."
  value = {
    for name in module.agents.node_names :
    name => <<-EOT
      k3sup join \
        --ip ${module.agents.public_ips[name]} \
        --server-ip ${module.servers.first_node_public_ip} \
        --user ${var.admin_username} \
        --k3s-extra-args '--disable traefik'
    EOT
  }
}
