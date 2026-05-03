resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project}"
  location = var.location
  tags     = local.tags
}
