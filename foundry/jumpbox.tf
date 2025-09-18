
# Create password for Jumpbox VM
resource "random_password" "vm_jumpbox_admin_password" {
  length  = 16
  special = true
}

# Create Network Interfaces
resource "azurerm_network_interface" "nic1" {
  name                = "nic1-vm-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    primary                       = true
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = null
    subnet_id                     = azurerm_subnet.subnet_jumpbox.id
    private_ip_address_allocation = "Dynamic"
    
  }
}

# Create Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm-jumpbox" {
  name                = "vm-jumpbox"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B4as_v2"
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
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# Install Azure CLI on Jumpbox
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
