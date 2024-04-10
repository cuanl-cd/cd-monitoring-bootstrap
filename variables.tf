// Required values

variable "customer_tenant_id" {
  description = "The customer's Entra ID tenant GUID."
  type        = string

  validation {
    condition     = length(var.customer_tenant_id) == 36
    error_message = "The customer_tenant_id must be a valid GUID."
    }
}

variable "customer_tenant_name" {
  description = "Cosmetic name for the customer tenant."
  type        = string

  validation {
    condition     = length(var.customer_tenant_name) > 0
    error_message = "The customer_tenant_name must be a valid string."
  }
}

variable "customer_subscription_id" {
  description = "Azure subscription GUID for the deployed resources."
  type        = string

  validation {
    condition     = length(var.customer_subscription_id) == 36
    error_message = "The customer_subscription_id must be a valid GUID."
  }
}

variable "customer_subscription_name" {
  description = "Cosmetic name for the Azure subscription. For Azure Landing Zone, the Management subscription is recommended."
  default     = "Management"
  type        = string

  validation {
    condition     = length(var.customer_subscription_name) > 0
    error_message = "The customer_subscription_name must be a valid string."
  }
}

variable "cd_azure_devops_pat_value" {
  description = "Value of the Azure DevOps personal access token"
  type        = string

  validation {
    condition     = length(var.cd_azure_devops_pat_value) > 0
    error_message = "The cd_azure_devops_pat_value must be a valid string."
  }
}

variable "cd_github_pat_value" {
  description = "Value of the GitHub fine grained personal access token"
  type        = string

  validation {
    condition     = length(var.cd_github_pat_value) > 0
    error_message = "The cd_github_pat_value must be a valid string."

  }
}


// Defaulted variables for Terraform state

variable "location" {
  description = "Specify the Azure region to deploy into."
  default     = "UK South"
  type        = string
}

variable "state_rg_name" {
  description = "Display name for the Terraform state resource group"
  default     = "azure-monitor-terraform-state"
  type        = string
}

variable "key_vault_rg_name" {
  description = "Display name of the Terraform state key vault resource group"
  default     = "azure-monitor-key-vault"
  type        = string
}

variable "storage_account_name" {
  description = "Display name of the storage account for the Terraform state"
  default     = null
  type        = string

  validation {
    condition     = var.storage_account_name == null ? true : (length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]*$", var.storage_account_name)))
    error_message = "The storage account name must be between 3 and 24 characters, and use only lowercase letters and numbers."
  }
}

variable "key_vault_name" {
  description = "Display name of the key vault"
  default     = "azure-monitor-key-vault"
  type        = string
}

// Variables for GitHub

variable "cd_github_org_name" {
  description = "Specify the Github Organization"
  default     = "Cloud-Direct-Morpheus"
  type        = string
}

// Variables for Azure DevOps

variable "devops_org_service_url" {
  description = "Specify the Azure DevOps Organization Service URL"
  default     = "https://dev.azure.com/clouddirect"
  type        = string
}

// Variables for tagging

variable "service_tag" {
  description = "Specify the Service Tag"
  default     = "Terraform"
  type        = string
}

variable "description_tag" {
  description = "Specify the Description Tag"
  default     = "Monitoring Bootstrap"
  type        = string
}

variable "org_tag" {
  description = "Specify the Org Tag"
  default     = "Cloud Direct"
  type        = string
}
