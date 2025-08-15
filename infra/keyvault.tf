
# Add Key Vault for Customer managed keys
resource "azurerm_key_vault" "kv-ai-assistant" {

  name                      = "kv-ai-assistant-e32dabgr"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "premium"
  enable_rbac_authorization = true

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
# Key Vault Keys
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

  depends_on = [azurerm_key_vault.kv-ai-assistant]
  tags       = var.tags
}

# Key Vault Role Assignments
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

resource "azurerm_role_assignment" "kv_role_assignment_004" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id
}

resource "azurerm_role_assignment" "kv_role_assignment_005" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id
}

resource "azurerm_role_assignment" "kv_role_assignment_006" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id
}

# Create Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "kv_vnet_dns_link" {
  name                  = "kv-vnet-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_ai_services.id
}

# Create Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_pe" {
  name                          = "pep-kv-ai-assistant"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  subnet_id                     = azurerm_subnet.subnet_pep.id
  custom_network_interface_name = "nic-pep-kv-ai-assistant"

  private_service_connection {
    name                           = "kv-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv-ai-assistant.id
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
