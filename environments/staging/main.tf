terraform {
  backend "local" {} # Override with Azure Storage backend for teams
}

module "common" {
  source = "../../modules/common"

  project     = var.project
  location    = var.location
  environment = var.environment
  tags        = var.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group   = module.common.resource_group
  project          = var.project
  tags             = module.common.tags
  allowed_ssh_cidr = var.allowed_ssh_cidr
  management_cidr  = var.management_cidr
}

module "lb" {
  source = "../../modules/loadbalancer"

  resource_group = module.common.resource_group
  project        = var.project
  tags           = module.common.tags
}

module "servers" {
  source = "../../modules/compute"

  resource_group      = module.common.resource_group
  project             = var.project
  tags                = module.common.tags
  node_names          = [for i in range(var.server_count) : "server-${i}"]
  vm_size             = var.server_vm_size
  zones               = ["1", "2", "3"]
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  subnet_id           = module.networking.subnet_id
  nsg_id              = module.networking.nsg_id
  enable_public_ip    = true
  associate_lb        = true
  lb_pool_id          = module.lb.backend_pool_id
}

module "agents" {
  source = "../../modules/compute"

  resource_group      = module.common.resource_group
  project             = var.project
  tags                = module.common.tags
  node_names          = [for i in range(var.agent_count) : "agent-${i}"]
  vm_size             = var.agent_vm_size
  zones               = [for i in range(var.agent_count) : element(["1", "2", "3"], i % 3)]
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  subnet_id           = module.networking.subnet_id
  nsg_id              = module.networking.nsg_id
  enable_public_ip    = true
  associate_lb        = true
  lb_pool_id          = module.lb.backend_pool_id
}
