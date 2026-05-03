terraform {
  # backend "local" {}  # Default: local state (fine for solo dev)
  #
  # For teams / production, switch to Azure Storage backend:
  # 1. Create storage account first (separate from this template):
  #    az group create --name tfstate-rg --location eastus
  #    az storage account create --name tfstate<unique> --resource-group tfstate-rg --sku Standard_LRS
  #    az storage container create --name tfstate --account-name tfstate<unique>
  # 2. Uncomment and configure:
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstate<unique>"     # Globally unique, 3-24 chars, lowercase
  #   container_name       = "tfstate"
  #   key                  = "single.terraform.tfstate"
  # }
  backend "local" {}
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

