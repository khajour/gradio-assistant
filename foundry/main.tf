
data "azurerm_resource_group" "rg" {
  name         = var.resource_group_name
}

data "azurerm_key_vault" "kv-ai-assistant" {
  name                = "kv-ai-assistant-e48dabgr"
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_key" "ai-foundry-key" {
  name         = "ai-foundry-key"
  key_vault_id = data.azurerm_key_vault.kv-ai-assistant.id
}


data "azurerm_client_config" "current" {
 
}


