output "vm_public_ip" {
  description = "Public IP of the single node. Use this for k3sup install and SSH."
  value       = module.node.public_ips["node-0"]
}

output "vm_private_ip" {
  description = "Private IP of the single node."
  value       = module.node.private_ips["node-0"]
}

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = module.common.resource_group_name
}


output "k3sup_init_command" {
  description = "Ready-to-run command to bootstrap k3s on the single node."
  value = <<-EOT
    k3sup install \
      --ip ${module.node.public_ips["node-0"]} \
      --user ${var.admin_username} \
      --tls-san ${module.node.public_ips["node-0"]} \
      --k3s-extra-args '--disable traefik'
  EOT
}
