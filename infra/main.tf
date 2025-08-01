provider "azurerm" {
  features {}
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
      defaultProject         = var.default_project_name
      publicNetworkAccess    = "Enabled"
      restore                = false
      allowProjectManagement = true
      customSubDomainName    = var.ai_foundry_name

      publicNetworkAccess = "Enabled" # Set to "Disabled" for private access only
      networkAcls = {
        defaultAction       = "Deny"
        virtualNetworkRules = [
          {
            id = azurerm_subnet.subnet_jumpbox.id
            ignoreMissingVnetServiceEndpoint = true
          
          },
                    {
            id = azurerm_subnet.subnet_pep.id
            ignoreMissingVnetServiceEndpoint = false
          }
        ]
        ipRules             = []
      }

      # encryption = {
      #   keySource = "Microsoft.KeyVault"
      #   identityClientId = azapi_resource.ai_foundry_instance.identity
      #   keyVaultProperties = {
      #     keyName = "ai-foundry-key"
      #     keyVaultUri = azurerm_key_vault.kv-ai-assistant.vault_uri
      #     keyVersion = "1.0.0"
      #   }
      # }

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

  depends_on                = [azurerm_resource_group.rg] # Add explicit dependency
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


## #############################################################
# Add Key Vault for AI Foundry
# #############################################################
resource "azurerm_key_vault" "kv-ai-assistant" {

  name                      = "kv-ai-assistant-e32dabgr"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  public_network_access_enabled   = false
  tags                            = var.tags
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

## #############################################################
# Create Windows VM for Jumpbox
# #############################################################
# Random Passwords for VMs
resource "random_password" "vm_jumpbox_admin_password" {
  length  = 16
  special = true
}

# Network Interfaces
resource "azurerm_network_interface" "nic1" {
  name                = "nic1-vm-jumpbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_jumpbox.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "vm-jumpbox" {
  name                = "vm-jumpbox"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D4as_v5"
  admin_username      = "azure-user"
  admin_password      = random_password.vm_jumpbox_admin_password.result
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]


  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
  }




  tags = var.tags
}


resource "azurerm_virtual_machine_extension" "installAzureCLI" {
  name                 = "installAzureCLI"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm-jumpbox.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'\""
  }
  SETTINGS
}

## #############################################################
# Create Bastion Host 
# #############################################################
resource "azurerm_public_ip" "pip_bastion" {
  name                = "pip_bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_we" {
  name                = "bastion-host"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.pip_bastion.id
  }
}

 data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "ai_foundry_role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Cognitive Services User" # Cognitive Services User
  principal_id         = data.azurerm_client_config.current.object_id
}