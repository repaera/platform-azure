resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.project}-k3s-nodes"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags
}

# SSH locked to your IP only
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.allowed_ssh_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# HTTP for Traefik / app traffic
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AllowHTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# HTTPS for secure app traffic
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "AllowHTTPS"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# K8s API for kubectl access — restricted to management CIDR
resource "azurerm_network_security_rule" "allow_k8s_api" {
  name                        = "AllowK8sAPI"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = coalesce(var.management_cidr, var.allowed_ssh_cidr)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# k3s internal cluster communication (node-to-node)
resource "azurerm_network_security_rule" "allow_k3s_internal" {
  name                        = "AllowK3sInternal"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10250"
  source_address_prefix       = var.subnet_address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# etcd peer communication (control plane HA)
resource "azurerm_network_security_rule" "allow_etcd" {
  name                        = "AllowEtcd"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "2379-2380"
  source_address_prefix       = var.subnet_address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Rancher dashboard UI — restricted to management CIDR
resource "azurerm_network_security_rule" "allow_rancher" {
  name                        = "AllowRancherDashboard"
  priority                    = 160
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8443"
  source_address_prefix       = coalesce(var.management_cidr, var.allowed_ssh_cidr)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Flannel VXLAN (node-to-node pod networking)
resource "azurerm_network_security_rule" "allow_vxlan" {
  name                        = "AllowVXLAN"
  priority                    = 170
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "8472"
  source_address_prefix       = var.subnet_address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
