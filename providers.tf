terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    github = {
      source  = "integrations/github"
      version = ">=6.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.customer_subscription_id
  storage_use_azuread = true
  tenant_id           = var.customer_tenant_id
}

provider "github" {
  owner = var.cd_github_org_name
  token = var.cd_github_pat_value
}
