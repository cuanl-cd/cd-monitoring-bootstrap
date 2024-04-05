// Create the customer Github Repository from template

resource "github_repository" "customer_github_repo" {
  name        = var.customer_repo_name
  description = var.customer_repo_description

  visibility = "private"

  template {
    owner                = var.cd_repo_template_owner
    repository           = var.cd_repo_template_name
    include_all_branches = true
  }
}


#data "azuread_client_config" "current" {}

// Create the Managed Identity for the customer Azure Environment

resource "azurerm_user_assigned_identity" "customer_managed_identity" {
  depends_on          = [azurerm_resource_group.mon_rg]
  location            = var.location
  name                = var.managed_identity
  resource_group_name = var.mon_rg
}

resource "azapi_resource" "federated_credential" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  parent_id = azurerm_user_assigned_identity.customer_managed_identity.id
  name      = var.federated_credential_display_name
  body = jsonencode({
    properties = {
      audiences = var.federated_credential_audiences
      issuer    = var.federated_credential_issuer
      subject   = "sc://clouddirect/AzureMonitoringV2-ClientDeployments/${var.CDDevOps_Service_Connection_Name}"
    }
  })
}

// Create the Resource Groups for the Monitoring and Logging

resource "azurerm_resource_group" "mon_rg" {
  name     = var.mon_rg
  location = var.location

  tags = local.common_tags

}

resource "azurerm_resource_group" "log_rg" {
  name     = var.log_rg
  location = var.location

  tags = local.common_tags

}

// Create the Role Assignments for the Managed Identity

resource "azurerm_role_assignment" "mon_rg_role_assignment" {
  scope                = azurerm_resource_group.mon_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.customer_managed_identity.principal_id

  depends_on = [ azurerm_resource_group.mon_rg ]
}

resource "azurerm_role_assignment" "log_rg_role_assignment" {
  scope                = azurerm_resource_group.log_rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.customer_managed_identity.principal_id

  depends_on = [ azurerm_resource_group.log_rg ]
}

//Create the DevOps Service Connection on Cloud Direct DevOps

data "azuredevops_project" "cd_devops_monitoring_project" {
  name = "AzureMonitoringV2-ClientDeployments"
}

resource "azuredevops_serviceendpoint_azurerm" "cddevops_cust_service_connection" {
  project_id                             = data.azuredevops_project.cd_devops_monitoring_project.id
  service_endpoint_name                  = var.CDDevOps_Service_Connection_Name
  description                            = var.cd_cust_service_connection_description
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.customer_managed_identity.client_id
  }
  azurerm_spn_tenantid      = var.cust_tenant_id
  azurerm_subscription_id   = var.azure_subscription_id
  azurerm_subscription_name = var.cust_subscription_name
}

// Create the Bicep Core Monitoring Components Parameters file

resource "local_file" "core_monitoring_components" {
  filename = "${path.module}/coreMonitoringComponents.bicepparam"
  content  = local.bicep_config
}

// Upload the Core Monitoring Components Bicep Parameters file into the customer repository on Cloud Direct Githubcheck "

resource "github_repository_file" "core_monitoring_components" {
  repository = github_repository.customer_github_repo.name
  file       = "coreMonitoringComponents.bicepparam"
  content    = local.bicep_config
  branch     = "main"
}

// Create the Workspace Deployment Bicep Parameters file

resource "local_file" "workspace_deployment" {
  filename = "${path.module}/workspaceDeployment.bicepparam"
  content  = local.workspaceDeployment_bicep
}

// Create the YAML file for pipeline deployment

resource "local_file" "yaml_file_deployment" {
  filename = "${path.module}/waf-sup-man-pipeline-vars.yaml"
  content  = local.pipline_yaml
}