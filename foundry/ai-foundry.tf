



###############################################################
# Create AI Foundry Instance
###############################################################

resource "azurerm_user_assigned_identity" "ai_foundry_identity" {
  name                = "ai_foundry_identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}
##############################################################
# Create AI Foundry Instance
##############################################################

resource "azapi_resource" "ai_foundry_instance" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = var.ai_foundry_name
  parent_id = data.azurerm_resource_group.rg.id
  location  = var.location

  // use system assigned identity for key vault access, mandatory for CMK
  identity {
    type = "SystemAssigned"
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
        defaultAction       = "Allow"
        virtualNetworkRules = []
        ipRules             = []
      }

      /*
      encryption = {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = {
          keyName     =  data.azurerm_key_vault_key.ai-foundry-key.name
          keyVaultUri = data.azurerm_key_vault.kv-ai-assistant.vault_uri
          keyVersion  = data.azurerm_key_vault_key.ai-foundry-key.version
          depends_on  = [azurerm_role_assignment.kv_role_assignment_kv10, azurerm_role_assignment.kv_role_assignment_008]
        }
      }
*/
      # Add network injections for agents private
      networkInjections = var.create_ai_agent_service ? [
        {
          subnetArmId                = azurerm_subnet.subnet_agents.id
          useMicrosoftManagedNetwork = false
        }
      ] : null

    }

  }
  schema_validation_enabled = false
  tags                      = var.tags
}


# #############################################################
# Update AI Foundry Instance to add CMK encryption
# #############################################################

resource "azapi_update_resource" "ai_foundry_instance" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  //name      = var.ai_foundry_name
  //parent_id = data.azurerm_resource_group.rg.id
  resource_id = azapi_resource.ai_foundry_instance.id


  body = {
    properties = {
      encryption = {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = {
          keyName     = data.azurerm_key_vault_key.ai-foundry-key.name
          keyVaultUri = data.azurerm_key_vault.kv-ai-assistant.vault_uri
          keyVersion  = data.azurerm_key_vault_key.ai-foundry-key.version
        }
      }
      apiProperties = {
        qnaAzureSearchEndpointKey = ""
      }
    }
  }
  depends_on = [azapi_resource.ai_foundry_instance]
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
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Cognitive Services User" # Cognitive Services User
  principal_id         = data.azurerm_client_config.current.object_id
}





# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "ai_foundry_dns_zone" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "ai_foundry_vnet_dns_link" {
  name                  = "ai-foundry-vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_foundry_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "openai_dns_zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_vnet_dns_link" {
  name                  = "openai-vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}
# #############################################################
# Create private dns zone for AI Foundry
# #############################################################
resource "azurerm_private_dns_zone" "cognitiveservices_dns_zone" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "cognitiveservices_vnet_dns_link" {
  name                  = "cognitiveservices-vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cognitiveservices_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# #############################################################
# Create private endpoint for AI Foundry
# #############################################################
resource "azurerm_private_endpoint" "ai_foundry_pe" {
  name                          = "pep-ai-foundry"
  location                      = var.location
  resource_group_name           = var.resource_group_name
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

# #############################################################
# Add Role Assignments for AI Foundry Identity to access Key Vault
# #############################################################

resource "azurerm_role_assignment" "kv_role_assignment_004" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = azapi_resource.ai_foundry_instance.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_role_assignment_005" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azapi_resource.ai_foundry_instance.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_role_assignment_006" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azapi_resource.ai_foundry_instance.identity[0].principal_id
}




// Add Key Vault Secrets User role for CMK
resource "azurerm_role_assignment" "kv_role_assignment_007" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azapi_resource.ai_foundry_instance.identity[0].principal_id
}

// Add Key Vault Crypto Service Encryption Userrole for CMK
resource "azurerm_role_assignment" "kv_role_assignment_008" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azapi_resource.ai_foundry_instance.identity[0].principal_id
}



