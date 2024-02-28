// Variables for TF State

variable "subscription_id" {
  description = "Specify the Azure Subscription to deploy into."
}

variable "location" {
  description = "Specify the Azure region to deploy into."
}

variable "state_rg_name" {
  description = "display name of the state resource group"
}

variable "keyvault_rg_name" {
  description = "display name of the keyvault resource group"
}

variable "storage_account_name" {
  description = "display name of the storage account for TF State"
}

variable "keyvault_name" {
  description = "display name of the keyvault"
}

// Variables for Tagging

variable "service_tag" {
  description = "Specify the Service Tag"
}

variable "description_tag" {
  description = "Specify the Description Tag"
}

variable "org_tag" {
  description = "Specify the Org Tag"
}
