terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6.1"
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.44.0"

    }
  }

}


#################################################################
# Provider Configuration
#################################################################
provider "azurerm" {
  features {
        key_vault  {
      purge_soft_delete_on_destroy = true
      purge_soft_deleted_keys_on_destroy = true
    }

    resource_group  {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  
}