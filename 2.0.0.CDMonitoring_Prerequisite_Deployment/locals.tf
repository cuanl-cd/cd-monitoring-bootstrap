locals {
  common_tags = {
    Provisioner = "Terraform"
    Workload    = "Logging and Monitoring"
  }
}

locals {
  resource_group_names = [var.log_rg, var.mon_rg]
}

locals {
  bicep_config = templatefile("${path.module}/coreMonitoringComponents.bicepparam.tftpl", {
    location                             = var.location
    law_workspace_name                   = var.law_workspace_name
    log_rg                               = var.log_rg
    action_group_email                   = var.action_group_email
    action_group                         = var.action_group
    config_action_group_email            = var.config_action_group_email
    configureActionGroupServiceUri       = var.configureActionGroupServiceUri
    deployDcr                            = var.deployDcr
    dcrIntervalSeconds                   = var.dcrIntervalSeconds
    deployIaaSAlerts                     = var.deployIaaSAlerts
    iaasHighCpuPercentageThreshold       = var.iaasHighCpuPercentageThreshold
    iaasMemoryThreshold                  = var.iaasMemoryThreshold
    iaasDiskSpaceLeftPercentageThreshold = var.iaasDiskSpaceLeftPercentageThreshold
    deployAdvisorAlerts                  = var.deployAdvisorAlerts
    deployHealthAlerts                   = var.deployHealthAlerts
    deployPaaSAlerts                     = var.deployPaaSAlerts
    deploySecurityAlerts                 = var.deploySecurityAlerts
    deploySqlIaaSAlerts                  = var.deploySqlIaaSAlerts
    deploySqlPaaSAlerts                  = var.deploySqlPaaSAlerts
  })
}

locals {
  workspaceDeployment_bicep = templatefile("${path.module}/workspaceDeployment.bicepparam.tftpl", {
    workspaceName    = var.law_workspace_name
    location         = var.location
    CDManaged_tag    = var.CDManaged_tag
    Owner_tag        = var.Owner_tag
    CDProductID_tag  = var.CDProductID_tag
    CDCustomerID_tag = var.CDCustomerID_tag
    DeployedBy_tag   = var.DeployedBy_tag
    serviceTier      = var.serviceTier
    dataRetention    = var.dataRetention
  })
}

locals {
  pipline_yaml = templatefile("${path.module}/waf-sup-man-pipeline-vars.yaml.tftpl", {
    serviceConnection                     = var.CDDevOps_Service_Connection_Name
    tenantId                              = var.cust_tenant_id
    workspaceSubscriptionId               = var.azure_subscription_id
    workspaceResourceGroupName            = var.log_rg
    monitoringComponents                  = var.deploy_monitoring_components
    MonitoringComponentsResourceGroupName = var.mon_rg
    deploymentStackName                   = var.deploymentStackName
  })
}

