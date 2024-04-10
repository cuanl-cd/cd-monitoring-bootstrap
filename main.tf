// Get Current Config

data "azurerm_client_config" "current" {}


// Locals configuration for later use

locals {
  uniq = substr(sha1(azurerm_resource_group.state.id), 0, 8)

  tags = tomap(
    {
      "service"     = var.service_tag
      "description" = var.description_tag
      "org"         = var.org_tag
    }
  )

  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "cdmonitoring${local.uniq}"

  terraform_providers = templatefile("${path.module}/templates/providers.tftpl", {
    state_resource_group_name       = var.state_rg_name
    state_storage_account_name      = local.storage_account_name
    state_storage_container_name    = azurerm_storage_container.state.name
    cd_github_pat_token_secret_name = azurerm_key_vault_secret.cd_github_pat.name
    cd_azure_devops_pat_secret_name = azurerm_key_vault_secret.cd_azure_devops_pat.name
    key_vault_id                    = azurerm_key_vault.key_vault.id
    devops_org_service_url          = var.devops_org_service_url
    cd_github_org_name              = var.cd_github_org_name
  })

  terraform_tfvars = templatefile("${path.module}/templates/terraform.tfvars.tftpl", {
    location                = var.location
    customer_subscription_id    = var.customer_subscription_id
    customer_subscription_name  = var.customer_subscription_name
    customer_tenant_id          = var.customer_tenant_id
    customer_tenant_name        = var.customer_tenant_name
    devops_key_vault_secret = azurerm_key_vault_secret.cd_azure_devops_pat.id
    github_key_vault_secret = azurerm_key_vault_secret.cd_github_pat.id
  })
}

// Create resource groups

resource "azurerm_resource_group" "state" {
  name     = var.state_rg_name
  location = var.location
  tags     = local.tags

  # lifecycle {
    # prevent_destroy = true
  # }
}

resource "azurerm_resource_group" "key_vault" {
  name     = var.key_vault_rg_name
  location = var.location
  tags     = local.tags

  # lifecycle {
    # prevent_destroy = true
  # }
}

// Create the storage account for Terraform state

resource "azurerm_storage_account" "state" {
  name                      = local.storage_account_name
  resource_group_name       = azurerm_resource_group.state.name
  location                  = azurerm_resource_group.state.location
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

  # lifecycle {
    # prevent_destroy = true
  # }
}

// Create the storage container for Terraform state

resource "azurerm_storage_container" "state" {
  name                  = "cdmonitoring-tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"

  # lifecycle {
    # prevent_destroy = true
  # }
}

// Create key vault for protected values

resource "azurerm_key_vault" "key_vault" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.key_vault.location
  resource_group_name        = azurerm_resource_group.key_vault.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  tags                       = local.tags
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
}

// Create RBAC for Key Vault

resource "azurerm_role_assignment" "key_vault_rbac_current_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_key_vault.key_vault]
}

// Create the key vault secrets for later use

resource "azurerm_key_vault_secret" "cd_azure_devops_pat" {
  name         = "cd-azure-devops-pat"
  value        = var.cd_azure_devops_pat_value
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_role_assignment.key_vault_rbac_current_user]
}

resource "azurerm_key_vault_secret" "cd_github_pat" {
  name         = "cd-github-pat"
  value        = var.cd_github_pat_value
  key_vault_id = azurerm_key_vault.key_vault.id

  depends_on = [azurerm_role_assignment.key_vault_rbac_current_user]
}

/*
//Create the provider file for the next module

resource "local_file" "terraform_providers" {
  filename = "${path.root}/../2.0.0.CDMonitoring_Prerequisite_Deployment/providers.tf"
  content  = local.terraform_providers
}

resource "local_file" "terraform_tfvars" {
  filename = "${path.root}/../2.0.0.CDMonitoring_Prerequisite_Deployment/terraform.tfvars"
  content  = local.terraform_tfvars
}
*/