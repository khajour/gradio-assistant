
###############################################################
# Create AI Foundry Instance
###############################################################

resource "azurerm_user_assigned_identity" "ai_foundry_identity" {
  name                = "ai_foundry_identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azapi_resource" "ai_foundry_instance" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = var.ai_foundry_name
  parent_id = azurerm_resource_group.rg.id
  location  = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ai_foundry_identity.id]
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      defaultProject         = var.default_project_name
      restore                = false
      allowProjectManagement = true
      customSubDomainName    = var.ai_foundry_name

      publicNetworkAccess = "Disabled"
      
      networkAcls = {
        defaultAction = "Allow"
        virtualNetworkRules = []
        ipRules = []
      }

      # Add network injections for agents private
      networkInjections = var.create_ai_agent_service ? [
        {
          subnetArmId                = azurerm_subnet.subnet_agents.id
          useMicrosoftManagedNetwork = false
        }
      ] : null
    }



/*
    encryption = {
      keySource = "Microsoft.KeyVault"
      keyVaultProperties = {
        keyName          = azurerm_key_vault_key.ai-foundry-key.name
        
        keyVaultUri      = azurerm_key_vault.kv-ai-assistant.vault_uri
        keyVersion       = azurerm_key_vault_key.ai-foundry-key.version
        identityClientId = azurerm_user_assigned_identity.ai_foundry_identity.client_id
      }
    }
*/

  }


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



  depends_on                = [azapi_resource.ai_foundry_instance]
  schema_validation_enabled = false
  tags                      = var.tags
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
        format : "OpenAI"
        name    = "gpt-4o"
        version = "2024-11-20"
      }
      raiPolicyName        = "Microsoft.DefaultV2"
      versionUpgradeOption = "NoAutoUpgrade"
    }
    sku = {
      name     = "DataZoneStandard"
      capacity = 50
    }
  }

  depends_on                = [azapi_resource.ai_project_instance]
  schema_validation_enabled = false
  tags                      = var.tags
}

resource "azurerm_role_assignment" "ai_foundry_role_assignment" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Cognitive Services User" # Cognitive Services User
  principal_id         = data.azurerm_client_config.current.object_id
}


# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "ai_foundry_dns_zone" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "ai_foundry_vnet_dns_link" {
  name                  = "ai-foundry-vnet-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_foundry_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "openai_dns_zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_vnet_dns_link" {
  name                  = "openai-vnet-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}
# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "cognitiveservices_dns_zone" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "cognitiveservices_vnet_dns_link" {
  name                  = "cognitiveservices-vnet-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitiveservices_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# #############################################################
# Create private endpoint for AI Foundry
# #############################################################
resource "azurerm_private_endpoint" "ai_foundry_pe" {
  name                          = "pep-ai-foundry"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.subnet_pep.id
  custom_network_interface_name = "nic-pep-ai-foundry"

  private_service_connection {
    name                           = "ai-foundry-psc"
    is_manual_connection           = false
    private_connection_resource_id = azapi_resource.ai_foundry_instance.id
    subresource_names              = ["account"]

  }

  depends_on = [azapi_resource.model_deployment]

  private_dns_zone_group {
    name = "ai-foundry-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_foundry_dns_zone.id,
      azurerm_private_dns_zone.openai_dns_zone.id,
    azurerm_private_dns_zone.cognitiveservices_dns_zone.id]

  }

  tags = var.tags
}
