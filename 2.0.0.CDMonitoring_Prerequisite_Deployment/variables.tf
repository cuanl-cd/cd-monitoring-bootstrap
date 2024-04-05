// Variables for creating the Service Principal

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
}

variable "cust_tenant_id" {
  description = "Azure Tenant ID"
}

variable "service_principal" {
  description = "Service Principal Name"
  default     = "cloud-direct-monitoring-sp"
}

variable "managed_identity" {
  description = "Name of the Managed Identity to be created"
}

// Variables for creating the Federated Credential

variable "CDDevOps_Service_Connection_Name" {
  description = "CD DevOps Service Connection Name"
}

variable "federated_credential_display_name" {
  description = "Federated Credential Display Name"
  default     = "cloud-direct-monitoring-federated-credential"
}

variable "federated_credential_name" {
  description = "Federated Credential Name"
  default     = "cloud-direct-monitoring-federated-credential"
}

variable "federated_credential_audiences" {
  description = "Federated Credential Audiences"
  type        = list(string)
  default     = ["api://AzureADTokenExchange"]
}

variable "federated_credential_issuer" {
  description = "Federated Credential Issuer"
  type        = string
  default     = "https://vstoken.dev.azure.com/80fa9e3e-beec-4e1e-800f-9965a08f5ddc"
}

// Variables for creating the Github Repository

variable "customer_repo_name" {
  description = "Customer Repository Name"
}

variable "customer_repo_description" {
  description = "Customer Repository Description"
  default     = "This repository contains the code for monitoring and alerting"
}

variable "customer_repo_private" {
  description = "Customer Repository Private"
  default     = true
}

variable "cd_repo_template_owner" {
  description = "The Github Organization or Username that owns the template repository"
  default     = "Cloud-Direct"
}

variable "cd_repo_template_name" {
  description = "The name of the template repository"
  default     = "Azure_Monitor_Client_Template"
}

// Variables for creating the pre-requisite Resource Groups in the customer environment

variable "log_rg" {
  description = "Name of the Resource Group that will host the customer Log Analytics Workspace"
}

variable "mon_rg" {
  description = "Name of the Resource Group that will host the customer Data Collection Rules & Alerts"
}

variable "identity_rg" {
  description = "Name of the Resource Group that will host the customer Managed Identity"
}

variable "location" {
  description = "Location of the customer Resource Groups"
  default     = "UK South"
}

// Variables for creating the customer Service Connection in Cloud Direct DevOps

variable "cd_cust_service_connection_description" {
  description = "Description of the Service Connection"
  default     = "Service Connection to deploy resources to the customer environment"
}

variable "cust_subscription_name" {
  description = "Name of the customer Azure Subscription"
}

// Variables for creating the core monitoring components bicep parameters

variable "law_workspace_name" {
  description = "Name of the Customer Log Analytics Workspace"
  type        = string
}

variable "action_group_email" {
  description = "Email address for the customer Action Group"
}

variable "cd_github_pat_token" {
  description = "Cloud Direct Github Personal Access Token"
}

variable "cd_devops_pat_token" {
  description = "Cloud Direct DevOps Personal Access Token"
}

variable "action_group" {
  description = "Action Group Parameter (true or false)"
  default     = true
}

variable "config_action_group_email" {
  description = "Config Action Group Parameter (true or false)"
  default     = false
}

variable "configureActionGroupServiceUri" {
  description = "Configure Action Group Service Uri"
  default     = false
}

variable "deployDcr" {
  description = "Deploy Data Collection Rules"
  default     = true
}

variable "dcrIntervalSeconds" {
  description = "Data Collection Rules Interval in Seconds"
  default     = "60"
}

variable "deployIaaSAlerts" {
  description = "Deploy IaaS Alerts"
  default     = true
}

variable "iaasHighCpuPercentageThreshold" {
  description = "IaaS High CPU Percentage Threshold"
  default     = "90"
}

variable "iaasMemoryThreshold" {
  description = "IaaS Memory Threshold"
  default     = "90"
}

variable "iaasDiskSpaceLeftPercentageThreshold" {
  description = "IaaS Disk Space Left Percentage Threshold"
  default     = "10"
}

variable "deployAdvisorAlerts" {
  description = "Deploy Advisor Alerts"
  default     = true
}

variable "deployHealthAlerts" {
  description = "Deploy Health Alerts"
  default     = true
}

variable "deployPaaSAlerts" {
  description = "Deploy PaaS Alerts"
  default     = true
}

variable "deploySecurityAlerts" {
  description = "Deploy Security Alerts"
  default     = true
}

variable "deploySqlIaaSAlerts" {
  description = "Deploy SQL IaaS Alerts"
  default     = true
}

variable "deploySqlPaaSAlerts" {
  description = "Deploy SQL PaaS Alerts"
  default     = true
}

// Variables for creating the workspace deployment bicep parameters

variable "CDManaged_tag" {
  description = "Tag to identify the resources managed by Cloud Direct"
}

variable "Owner_tag" {
  description = "Tag to identify the owner of the resources"
}

variable "CDProductID_tag" {
  description = "Tag to identify the product ID"
}

variable "CDCustomerID_tag" {
  description = "Tag to identify the customer ID"
}

variable "DeployedBy_tag" {
  description = "Tag to identify the person or method used deployed the resources"
}

variable "serviceTier" {
  description = "Service Tier for the Log Analytics Workspace"
}

variable "dataRetention" {
  description = "Data Retention for the Log Analytics Workspace"
}

// Variables for creating the pipeline yaml file

variable "deploy_monitoring_components" {
  description = "Deploy Monitoring Components"
  default     = true
}

variable "deploymentStackName" {
  description = "Deployment Stack Name"
  default     = "stack-cd-monitoring"
}
