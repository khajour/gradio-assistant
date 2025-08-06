# Create the VNET for Private Endpoint
resource "azurerm_virtual_network" "vnet_ai_services" {
    name                = var.vnet_ai_services_name
    depends_on          = [azurerm_resource_group.rg]
    address_space       = [var.vnet_ai_services_address_space]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags
}

# Create the Subnet for Private Endpoint
resource "azurerm_subnet" "subnet_pep" {
    name                                          = var.subnet_pep_name
    depends_on                                    = [azurerm_virtual_network.vnet_ai_services]
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_pep_address_space]
    service_endpoints                              = ["Microsoft.CognitiveServices"]

}

# Create the Subnet for Agents if AI Agent Service is enabled
resource "azurerm_subnet" "subnet_agents" {
    name                                          = var.subnet_agents_name
    depends_on                                    = [azurerm_virtual_network.vnet_ai_services]
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_agents_address_space]

}

# Create the Subnet for Private Endpoint
resource "azurerm_subnet" "subnet_jumpbox" {
    name                                          = "subnet-jumpbox"
    depends_on                                    = [azurerm_virtual_network.vnet_ai_services]
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_jumpbox_address_space]
    service_endpoints                              = ["Microsoft.CognitiveServices"] ## Add service endpoint for Cognitive Services to enable firewall access from cognitive services

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



resource "azurerm_private_dns_zone" "vault_dns_zone" {
  name                = "vault.contoso.com"
  resource_group_name = azurerm_resource_group.rg.name
}


# Create the Subnet for Bastion Host 
resource "azurerm_subnet" "AzureBastionSubnet" {
    name                                          = "AzureBastionSubnet"
    depends_on                                    = [azurerm_virtual_network.vnet_ai_services]
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_bastion_address_space]

}

# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "ai_foundry_dns_zone" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "openai_dns_zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "cognitiveservices_dns_zone" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}



# #############################################################
# Create private endpoint for AI Foundry
# #############################################################
resource "azurerm_private_endpoint" "ai_foundry_pe" {
  name                = "pep-ai-foundry"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pep.id
  custom_network_interface_name = "nic-pep-ai-foundry"

  private_dns_zone_group {
    name                 = "ai-foundry-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.ai_foundry_dns_zone.id, 
    azurerm_private_dns_zone.openai_dns_zone.id, 
    azurerm_private_dns_zone.cognitiveservices_dns_zone.id]
  }

  private_service_connection {
    name                           = "ai-foundry-psc"
    is_manual_connection           = false
    private_connection_resource_id = azapi_resource.ai_foundry_instance.id
    subresource_names              = ["account"]

  }

  tags = var.tags
}