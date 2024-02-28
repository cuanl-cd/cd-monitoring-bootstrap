// Get Current Config

data "azurerm_client_config" "current" {}

// Create Resource Groups

resource "azurerm_resource_group" "State" {
  name     = var.state_rg_name
  location = var.location
  tags     = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "KeyVault" {
  name     = var.keyvault_rg_name
  location = var.location
  tags     = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

// Create the Storage Account for TF State

resource "azurerm_storage_account" "State" {
  name                      = lower(var.storage_account_name)
  resource_group_name       = azurerm_resource_group.State.name
  location                  = var.location
  account_tier              = "Standard"
  account_kind              = "BlobStorage"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  tags                      = local.tags
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 365
    }
    container_delete_retention_policy {
      days = 90
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

// Create the Storage Container for TF State

resource "azurerm_storage_container" "State" {
  name                  = lower("cdmonitoring-tfstate")
  storage_account_name  = azurerm_storage_account.State.name
  container_access_type = "private"
  lifecycle {
    prevent_destroy = true
  }
}

// Create Key Vault for protected values

resource "azurerm_key_vault" "KeyVault" {
  name                       = var.keyvault_name
  location                   = azurerm_resource_group.KeyVault.location
  resource_group_name        = azurerm_resource_group.KeyVault.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  tags                       = local.tags
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  enable_rbac_authorization = true

}

// Create RBAC for Key Vault

resource "azurerm_role_assignment" "key_vault_rbac_current_user" {
  scope                = azurerm_key_vault.KeyVault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

// Create theKey Vault Secrets for later use

resource "azurerm_key_vault_secret" "cd_azure_devops_pat" {
  name         = "cd-azure-devops-pat"
  value        = ""
  key_vault_id = azurerm_key_vault.KeyVault.id
}

resource "azurerm_key_vault_secret" "cd_github_pat" {
  name         = "cd-github-pat"
  value        = ""
  key_vault_id = azurerm_key_vault.KeyVault.id
}

//Create the provider file for the next module

resource "local_file" "terraform_providers" {
  filename = "${path.root}/../2.0.0.CDMonitoring_Prerequisite_Deployment/providers.tf"
  content  = local.terraform_providers
}