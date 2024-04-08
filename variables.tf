// Variables for TF State

variable "cust_subscription_id" {
  description = "Specify the Azure Subscription to deploy into."
}

variable "cust_subscription_name" {
  description = "Specify the Azure Subscription to deploy into."
}

variable "cust_tenant_name" {
  description = "Specify the Azure Subscription to deploy into."
}

variable "cust_tenant_id" {
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

variable "cd_azure_devops_pat_value" {
  description = "value of the Azure DevOps PAT"
}

variable "cd_github_pat_value" {
  description = "value of the GitHub PAT"
}

// Variables for Azure DevOps

variable "devops_org_service_url" {
  description = "Specify the Azure DevOps Organization Service URL"
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

variable "cd_github_org_name" {
  description = "Specify the Github Organization"
}
