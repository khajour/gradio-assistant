# Create the VNET for Private Endpoint
resource "azurerm_virtual_network" "vnet_ai_services" {
    name                = var.vnet_ai_services_name
    address_space       = [var.vnet_ai_services_address_space]
    location            = var.location
    resource_group_name = var.resource_group_name

    tags                = var.tags
}

# Create the Subnet for Private Endpoint
resource "azurerm_subnet" "subnet_pep" {
    name                                          = var.subnet_pep_name
    resource_group_name                           = var.resource_group_name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_pep_address_space]

}

# Create the Subnet for Agents if AI Agent Service is enabled
resource "azurerm_subnet" "subnet_agents" {
    name                                          = var.subnet_agents_name
    resource_group_name                           = var.resource_group_name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_agents_address_space]
}

# Create the Subnet for jumbox
resource "azurerm_subnet" "subnet_jumpbox" {
    name                                          = "subnet-jumpbox"
    resource_group_name                           = var.resource_group_name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_jumpbox_address_space]
}

# Create the Subnet for Bastion Host 
resource "azurerm_subnet" "AzureBastionSubnet" {
    name                                          = "AzureBastionSubnet"
    resource_group_name                           = var.resource_group_name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_bastion_address_space]
}

# Create the Subnet for VPN Gateway
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = var.subnet_vpn_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_ai_services.name
  address_prefixes     = [var.subnet_vpn_address_space]
}

# Network Security Group for additional security
resource "azurerm_network_security_group" "nsg_main" {
  name                = "nsg_main"
  location            = var.location
  resource_group_name = var.resource_group_name
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
    name                       = "DenyInboundFromInternet"
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

# Create Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "kv_vnet_dns_link" {
  name                  = "kv-vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# Create Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_pe" {
  name                          = "pep-kv-ai-assistant"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = azurerm_subnet.subnet_pep.id
  custom_network_interface_name = "nic-pep-kv-ai-assistant"

  private_service_connection {
    name                           = "kv-psc"
    is_manual_connection           = false
    private_connection_resource_id = data.azurerm_key_vault.kv-ai-assistant.id
    subresource_names              = ["Vault"]

  }

  # Create Private DNS Zone Group for Key Vault
  private_dns_zone_group {
    name = "kv-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.kv_dns_zone.id
    ]
  }
  tags = var.tags
}