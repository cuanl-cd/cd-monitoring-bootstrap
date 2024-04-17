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

// Create resource groups

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

resource "azurerm_role_assignment" "github" {
  for_each             = toset(["Monitoring Contributor", "Storage Blob Data Contributor"])
  scope                = azurerm_resource_group.rg.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_definition" "deployment_stacks_contributor" {
  name        = "Deployment Stacks Contributor"
  scope       = azurerm_resource_group.rg.id
  description = "Custom role to manage deployment stacks and deployments."

  permissions {
    actions = [
      "Microsoft.Resources/deploymentStacks/*",
      "Microsoft.Resources/deployments/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.rg.id
  ]
}

resource "azurerm_role_assignment" "deployment_stacks_contributor" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.deployment_stacks_contributor.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_definition" "workspace_link_contributor" {
  name        = "Azure Monitor Workspace Link Contributor"
  scope       = local.workspace_resource_group_id
  description = "Custom role to link DCRs to an Azure Monitor workspace."

  permissions {
    actions = [
      "Microsoft.Insights/scheduledQueryRules/*",
      "Microsoft.OperationalInsights/workspaces/read",
      "Microsoft.OperationalInsights/workspaces/sharedKeys/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    local.workspace_resource_group_id
  ]
}

resource "azurerm_role_assignment" "workspace_link_contributor" {
  scope              = local.workspace_resource_group_id
  role_definition_id = azurerm_role_definition.workspace_link_contributor.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

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
    "MASTER_TEMPLATES_GIT_ORG"      = "Cloud-Direct",
    "MASTER_TEMPLATES_GIT_REPO"     = "cd-monitoring-azure-templates",
    "MASTER_TEMPLATES_GIT_BRANCH"   = "main"
  }

  repository    = var.cd_github_repo_name
  variable_name = each.key
  value         = each.value
}

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

resource "github_actions_variable" "ssh_key" {
  repository    = var.cd_github_repo_name
  variable_name = "SSH_KEY"
  value         = file("${path.module}/secrets/ssh_key.txt")
}

resource "github_actions_secret" "known_hosts" {
  repository      = var.cd_github_repo_name
  secret_name     = "KNOWN_HOSTS"
  plaintext_value = file("${path.module}/secrets/known_hosts.txt")
}

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
