locals {
  base_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
  tags = merge(local.base_tags, var.tags)
}
