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
