provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
#################################################################
# Create Resource Group
#################################################################


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}


###############################################################
# Create AI Foundry Instance
###############################################################


resource "azapi_resource" "ai_foundry_instance" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = var.ai_foundry_name
  parent_id = azurerm_resource_group.rg.id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      defaultProject          = var.default_project_name
      publicNetworkAccess     = "Enabled"
      restore                 = false
      allowProjectManagement = true
      customSubDomainName     = var.ai_foundry_name

      publicNetworkAccess = "Disabled"  # Set to "Disabled" for private access only
      networkAcls = {
        defaultAction       = "Deny"
        virtualNetworkRules = []
        ipRules             = []
      }

      # Add network injections  for agents private
       networkInjections = var.create_ai_agent_service ? [
         {
      #    scenario                   = "agent"
           subnetArmId                = azurerm_subnet.subnet_agents.id
           useMicrosoftManagedNetwork = false
         }
       ] : null
    }
  }

  depends_on                = [azurerm_resource_group.rg]  # Add explicit dependency
  schema_validation_enabled = false
  tags                      = var.tags
}

# #############################################################
# Create AI Project Instance
# #############################################################

resource "azapi_resource" "ai_project_instance" {
  location  = var.location
  name      = var.ai_project_name
  parent_id = azapi_resource.ai_foundry_instance.id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  
  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = var.ai_project_name
      description = "AI Project for ${var.ai_project_name} workloads"
    }
  }

  

  depends_on = [azapi_resource.ai_foundry_instance]
  schema_validation_enabled = false
  tags = var.tags
}

# #############################################################
# Add o4-mini Model deployment to AI Project
# #############################################################

resource "azapi_resource" "model_deployment" {
  location  = var.location
  name      = "gpt-4o-model_deployment"
  parent_id = azapi_resource.ai_foundry_instance.id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"

  body = {
    properties = {
      model = {
        format: "OpenAI"
        name = "gpt-4o"
        version = "2024-11-20"
      }
      raiPolicyName = "Microsoft.DefaultV2"
      versionUpgradeOption = "NoAutoUpgrade"
    }
    sku = {
      name = "DataZoneStandard"
      capacity = 50
    }
  }

  depends_on = [azapi_resource.ai_project_instance]
  schema_validation_enabled = false
  tags = var.tags
}

# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "ai_foundry_dns" {
  name                = "ai.contoso.com"
  resource_group_name = azurerm_resource_group.rg.name

}

# #############################################################
# Create dns zone link to  for ai_services vnet
# #############################################################

resource "azurerm_private_dns_zone_virtual_network_link" "ai_foundry_dns_link" {
  name                = "${var.ai_foundry_name}-dns-link"
  resource_group_name = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_foundry_dns.name
  virtual_network_id  = azurerm_virtual_network.vnet_ai_services.id
}

# Create private endpoint for AI Foundry
# #############################################################
resource "azurerm_private_endpoint" "ai_foundry_pe" {
  name                = "${var.ai_foundry_name}-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pep.id

  private_service_connection {
    name                           = "ai-foundry-psc"
    is_manual_connection           = false
    private_connection_resource_id = azapi_resource.ai_foundry_instance.id
    subresource_names              = ["account"]
  }

  tags = var.tags
}