#################################################################
# Provider Configuration
#################################################################
provider "azurerm" {
  features {
        key_vault  {
      purge_soft_delete_on_destroy = true
    }

    resource_group  {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  
}

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

