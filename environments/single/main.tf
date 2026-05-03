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

  resource_group  = module.common.resource_group
  project         = var.project
  tags            = module.common.tags
  allowed_ssh_cidr = var.allowed_ssh_cidr
  management_cidr  = var.management_cidr
}

module "node" {
  source = "../../modules/compute"

  resource_group      = module.common.resource_group
  project             = var.project
  tags                = module.common.tags
  node_names          = ["node-0"]
  vm_size             = var.vm_size
  zones               = []
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  subnet_id           = module.networking.subnet_id
  nsg_id              = module.networking.nsg_id
  enable_public_ip    = true
  associate_lb        = false
}

