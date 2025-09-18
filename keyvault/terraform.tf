#################################################################
# Required Providers 
#################################################################
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.44.0"

    }
  }

}

#################################################################
# Providers Configuration
#################################################################
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy       = true
      recover_soft_deleted_key_vaults    = false
      purge_soft_deleted_keys_on_destroy = true
    }


    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id

}
