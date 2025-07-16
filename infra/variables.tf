variable "location" {
  type        = string
  description = "Azure region for deployment"
  nullable    = false
  default     = "westeurope"
}
    
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "ai_foundry_name" {
  type        = string
  description = "Name of the AI Foundry account"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account used by AI Foundry"
}

variable "keyvault_name" {
  type        = string
  description = "Name of the keyvault account used by AI Foundry"
}


variable "subscription_id" {
  type        = string
  description = "id of the subscription used by AI Foundry"
}

variable "tenant_id" {
  type        = string
  description = "id of the tenant used by AI Foundry"
}


variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network for private endpoints"
}
variable "vnet_address_space" {
  type        = string
  description = "Address space for the virtual network"
}
variable "subnet_name" {
  type        = string
  description = "Name of the subnet for private endpoints"
}

variable "subnet_address_space" {
  type        = string
  description = "Address space for the subnet for private endpoints"
}

variable "publicNetworkAccess" {
  type        = string
  description = "Flag to create private endpoints for AI Foundry"
  default     = "Disabled"
}

variable "create_private_endpoints" {
  type        = bool
  description = "Flag to create private endpoints for AI Foundry"
  default     = false
}

variable "create_ai_agent_service" {
  type        = bool
  description = "Flag to create AI Agent service with VNet injection"
  default     = false
}