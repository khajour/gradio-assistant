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
    private_link_service_network_policies_enabled = true

}

# Create the Subnet for Agents if AI Agent Service is enabled
resource "azurerm_subnet" "subnet_agents" {
    name                                          = var.subnet_agents_name
    depends_on                                    = [azurerm_virtual_network.vnet_ai_services]
    resource_group_name                           = azurerm_resource_group.rg.name
    virtual_network_name                          = azurerm_virtual_network.vnet_ai_services.name
    address_prefixes                              = [var.subnet_agents_address_space]
    private_link_service_network_policies_enabled = true

}


# Network Security Group for additional security
resource "azurerm_network_security_group" "nsg_main" {
  name                = "var.nsg_main_name"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Allow inbound HTTPS from VNet only
  security_rule {
    name                       = "AllowVNetHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"     # More secure
    destination_address_prefix = "VirtualNetwork"     # More secure
  }

  # Allow Azure service communication
  security_rule {
    name                       = "AllowAzureCloud"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet_pep.id  
  network_security_group_id = azurerm_network_security_group.nsg_main.id
}