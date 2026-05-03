resource "azurerm_linux_virtual_machine" "node" {
  for_each = local.nodes

  name                = "vm-${var.project}-${each.key}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags
  zone                = each.value.zone

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  disable_password_authentication = true

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
