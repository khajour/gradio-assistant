provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create the VNET for Private Endpoint
resource "azurerm_virtual_network" "vnetmain" {
  name                = var.virtual_network_name
  depends_on = [var.resource_group_name]
  address_space       = [var.vnet_address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
}



# Create the Subnet for Private Endpoint
resource "azurerm_subnet" "subnetmain" {
  name                 = var.subnet_name
  depends_on = [azurerm_virtual_network.vnetmain]
  resource_group_name  =  azurerm_resource_group.rg.name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_space]
  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies = "Enabled"

}



resource "azapi_resource" "ai_foundry" {
  location  = var.location
  name      = var.ai_foundry_name
  parent_id = azurerm_resource_group.rg.id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = {

    kind = "AIServices",
    sku = {
      tier = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      restore = true
      disableLocalAuth       = false
      allowProjectManagement = true
      customSubDomainName    = var.ai_foundry_name
      publicNetworkAccess    = var.publicNetworkAccess
      networkAcls = {
        defaultAction       = "Allow"
        virtualNetworkRules = []
        ipRules             = []
      }

      # Enable VNet injection for Standard Agents
      networkInjections = var.create_ai_agent_service ? [
        {
          scenario                   = "agent"
          subnetArmId                = azurerm_subnet.subnetmain.id
          useMicrosoftManagedNetwork = false
        }
      ] : null
    }
  }
  schema_validation_enabled = false
  tags                      = var.tags
}