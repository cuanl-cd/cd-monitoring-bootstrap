data "azurerm_client_config" "current" {}

locals {
  uniq = substr(sha1(azurerm_resource_group.rg.id), 0, 8)

  tags = tomap(
    {
      "service"     = var.service_tag
      "description" = var.description_tag
      "org"         = var.org_tag
    }
  )

  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "cdmonitoring${local.uniq}"
  resource_group_name  = var.resource_group_name != null ? var.resource_group_name : "rg-cdmonitoring-prod-${local.region_short}-001"

  repo = format("%s/%s", var.cd_github_org_name, var.cd_github_repo_name)

  subject = format("repo:%s:job_workflow_ref:%s/.github/workflows/%s@refs/heads/%s",
    local.repo,
    local.repo,
    "monitoring.yaml",
    "main"
  )

  region_map = {
    "UK South" = "uksouth"
    "UK West"  = "ukwest"
  }

  region_short = try(local.region_map[var.location], replace(lower(var.location), " ", ""))
}

// Create resource groups

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  account_tier              = "Standard"
  account_kind              = "BlobStorage"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 365
    }
    container_delete_retention_policy {
      days = 90
    }
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "cdmonitoring-tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.state
  ]
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-cdmonitoring-prod-${local.region_short}-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_federated_identity_credential" "github" {
  name                = var.cd_github_repo_name
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.github.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = "https://token.actions.githubusercontent.com"
  subject  = local.subject
}

resource "azurerm_role_assignment" "example" {
  for_each             = toset(["Tag Contributor", "Monitoring Contributor", "Storage Blob Data Contributor"])
  scope                = azurerm_resource_group.rg.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "github_actions_variable" "github" {
  for_each = {
    "tenant_id"                     = var.customer_tenant_id,
    "subscription_id"               = var.customer_subscription_id,
    "client_id"                     = azurerm_user_assigned_identity.github.client_id,
    "resource_group_name"           = azurerm_resource_group.rg.name,
    "storage_account_name"          = azurerm_storage_account.state.name,
    "workspace_subscription_id"     = split("/", var.workspace_id)[2],
    "workspace_resource_group_name" = split("/", var.workspace_id)[4],
    "workspace_name"                = split("/", var.workspace_id)[8],
    "workspace_id"                  = var.workspace_id
  }

  repository    = var.cd_github_repo_name
  variable_name = each.key
  value         = each.value
}
