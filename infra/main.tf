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

      # Remove network injections temporarily to isolate the issue
      # networkInjections = var.create_ai_agent_service ? [
      #   {
      #     scenario                   = "agent"
      #     subnetArmId                = azurerm_subnet.subnet_pep.id
      #     useMicrosoftManagedNetwork = false
      #   }
      # ] : null
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