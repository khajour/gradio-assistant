# Create the VNET for Private Endpoint
resource "azurerm_virtual_network" "vnet_ai_services" {
    name                = var.vnet_ai_services_name
    address_space       = [var.vnet_ai_services_address_space]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    tags                = var.tags
}

# Create the Subnet for Private Endpoint
resource "azurerm_subnet" "subnet_pep" {
    name                                          = var.subnet_pep_name
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_pep_address_space]

}

# Create the Subnet for Agents if AI Agent Service is enabled
resource "azurerm_subnet" "subnet_agents" {
    name                                          = var.subnet_agents_name
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_agents_address_space]
}

# Create the Subnet for jumbox
resource "azurerm_subnet" "subnet_jumpbox" {
    name                                          = "subnet-jumpbox"
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_jumpbox_address_space]
}

# Create the Subnet for Bastion Host 
resource "azurerm_subnet" "AzureBastionSubnet" {
    name                                          = "AzureBastionSubnet"
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_bastion_address_space]
}

# Create the Subnet for VPN Gateway
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = var.subnet_vpn_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_ai_services.name
  address_prefixes     = [var.subnet_vpn_address_space]
}

# Network Security Group for additional security
resource "azurerm_network_security_group" "nsg_main" {
  name                = "nsg_main"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowAzureCloud"
    priority                   = 500
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 600
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowRDPInboundInternet"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureCloud"
    priority                   = 800
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  

}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_001" {
  subnet_id                 = azurerm_subnet.subnet_pep.id  
  network_security_group_id = azurerm_network_security_group.nsg_main.id
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_002" {
  subnet_id                 = azurerm_subnet.subnet_agents.id
  network_security_group_id = azurerm_network_security_group.nsg_main.id
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_003" {
  subnet_id                 = azurerm_subnet.subnet_jumpbox.id
  network_security_group_id = azurerm_network_security_group.nsg_main.id
}