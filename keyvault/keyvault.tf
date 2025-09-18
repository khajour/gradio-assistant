#################################################################
# Client Configuration
#################################################################

data "azurerm_client_config" "current" {
 
}
#################################################################
# Create Resource Group
#################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
#################################################################
# Create Key Vault for Customer managed keys
#################################################################

resource "azurerm_key_vault" "kv-ai-assistant" {

  name                      = "kv-ai-assistant-e48dabgr"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "premium"
  rbac_authorization_enabled = true

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true

  public_network_access_enabled = true
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
    ip_rules       = []
  }
  tags = var.tags

}

#################################################################
# Key Vault Role Assignments for current user
#################################################################

resource "azurerm_role_assignment" "kv_role_assignment_001" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.kv-ai-assistant]
}

resource "azurerm_role_assignment" "kv_role_assignment_002" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.kv-ai-assistant]
}

resource "azurerm_role_assignment" "kv_role_assignment_003" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.kv-ai-assistant]
}

// Add Key Vault Secrets User role for CMK
resource "azurerm_role_assignment" "kv_role_assignment_kv10" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}


#################################################################
# Key Vault Keys
#################################################################
resource "azurerm_key_vault_key" "ai-foundry-key" {
  name         = "ai-foundry-key"
  key_vault_id = azurerm_key_vault.kv-ai-assistant.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [azurerm_role_assignment.kv_role_assignment_001, azurerm_role_assignment.kv_role_assignment_002, azurerm_role_assignment.kv_role_assignment_003]
  tags       = var.tags
}

