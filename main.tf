data "azurerm_client_config" "current" {}

locals {
  uniq = substr(sha1(azurerm_resource_group.rg.id), 0, 8)

  resource_group_name  = var.resource_group_name != null ? var.resource_group_name : "rg-cdmonitoring-prod-${local.region_short}-001"
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "cdmonitoring${local.uniq}"

  region_map = {
    "UK South" = "uksouth"
    "UK West"  = "ukwest"
  }

  region_short = try(local.region_map[var.location], replace(lower(var.location), " ", ""))

  workspace_resource_group_id = join("/", slice(split("/", var.workspace_id), 0, 5))
}

// Resource group and storage account

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

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

// User assigned identities

// Core managed identity used to create the monitoring resources for the lifecycle of the service.
resource "azurerm_user_assigned_identity" "github" {
  name                = "id-cdmonitoring-prod-${local.region_short}-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_federated_identity_credential" "github" {
  name                = replace(var.cd_github_repo_name, "-", "_")
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.github.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = "https://token.actions.githubusercontent.com"
  subject  = "repo:${var.cd_github_org_name}/${var.cd_github_repo_name}:ref:refs/heads/main"
}

// For optional use in policy assignments. Better naming convention than the system generated name.
resource "azurerm_user_assigned_identity" "policy" {
  name                = "id-cdmonitoring-policy-prod-${local.region_short}-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}



// RBAC role assignments

resource "azurerm_role_assignment" "resource_group" {
  for_each             = toset(var.rbac ? ["Azure Deployment Stack Contributor", "Monitoring Contributor", "Storage Blob Data Contributor"] : [])
  scope                = azurerm_resource_group.rg.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}


resource "azurerm_role_assignment" "workspace" {
  for_each             = toset(var.rbac ? ["Contributor"] : [])
  scope                = var.workspace_id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

// Github Actions - Variables

resource "github_actions_variable" "github" {
  for_each = {
    "TENANT_ID"                     = var.customer_tenant_id,
    "SUBSCRIPTION_ID"               = var.customer_subscription_id,
    "RESOURCE_GROUP_NAME"           = azurerm_resource_group.rg.name,
    "STORAGE_ACCOUNT_NAME"          = azurerm_storage_account.state.name,
    "LOCATION"                      = var.location,
    "WORKSPACE_SUBSCRIPTION_ID"     = split("/", var.workspace_id)[2],
    "WORKSPACE_RESOURCE_GROUP_NAME" = split("/", var.workspace_id)[4],
    "WORKSPACE_NAME"                = split("/", var.workspace_id)[8],
    "WORKSPACE_ID"                  = var.workspace_id,
    "MASTER_TEMPLATES_GIT_ORG"      = "Cloud-Direct-Monitoring",
    "MASTER_TEMPLATES_GIT_REPO"     = "cd-monitoring-azure-templates",
    "MASTER_TEMPLATES_GIT_BRANCH"   = "main"
  }

  repository    = var.cd_github_repo_name
  variable_name = each.key
  value         = each.value
}

// Github Actions - Secrets

resource "github_actions_secret" "client_id" {
  repository      = var.cd_github_repo_name
  secret_name     = "CLIENT_ID"
  plaintext_value = azurerm_user_assigned_identity.github.client_id
}

resource "github_actions_secret" "app_id" {
  repository      = var.cd_github_repo_name
  secret_name     = "MONITORING_MODULE_APP_ID"
  plaintext_value = "877225"
}

resource "github_actions_secret" "private_key" {
  repository      = var.cd_github_repo_name
  secret_name     = "MONITORING_MODULE_PRIVATE_KEY"
  plaintext_value = file("${path.module}/secrets/github_app.pem")
}

resource "github_actions_secret" "ssh_key" {
  repository      = var.cd_github_repo_name
  secret_name     = "SSH_KEY"
  plaintext_value = file("${path.module}/secrets/ssh_key.txt")
}

resource "github_actions_secret" "known_hosts" {
  repository      = var.cd_github_repo_name
  secret_name     = "KNOWN_HOSTS"
  plaintext_value = file("${path.module}/secrets/known_hosts.txt")
}

resource "github_actions_secret" "ms_teams_webhook_uri" {
  repository      = var.cd_github_repo_name
  secret_name     = "MS_TEAMS_WEBHOOK_URI"
  plaintext_value = file("${path.module}/secrets/ms_teams_webhook_uri.txt")
}

//Github Repository Files

resource "github_repository_file" "tfvars" {
  repository          = var.cd_github_repo_name
  branch              = "main"
  file                = "terraform/bootstrap.auto.tfvars"
  overwrite_on_create = true

  content = <<-EOF
  subscription_id               = "${var.customer_subscription_id}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  storage_account_name          = "${azurerm_storage_account.state.name}"
  location                      = "${var.location}"

  tags = ${jsonencode(var.tags != null ? var.tags : {})}
  EOF
}

resource "github_repository_file" "bicep_params" {
  repository          = var.cd_github_repo_name
  branch              = "main"
  file                = "parameters/coreMonitoringComponents.bicepparam"
  overwrite_on_create = true

  content = templatefile("${path.module}/templates/coreMonitoringComponents.bicepparam.tftpl", {
    location                      = var.location,
    workspace_resource_group_name = split("/", var.workspace_id)[4],
    workspace_name                = split("/", var.workspace_id)[8],
    action_group_webhook_uri      = file("${path.module}/secrets/action_group_webhook_uri.txt")
  })
}
