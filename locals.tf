locals {
  tags = tomap(
    {
      "service"     = var.service_tag
      "description" = var.description_tag
      "org"         = var.org_tag
    }
  )
}

locals {
  terraform_providers = templatefile("${path.module}/providers.tftpl", {
    state_resource_group_name    = var.state_rg_name
    state_storage_account_name = var.storage_account_name
    state_storage_container_name = azurerm_storage_container.State.name
    cd_github_pat_token_secret_name = azurerm_key_vault_secret.cd_github_pat.name
    cd_azure_devops_pat_secret_name = azurerm_key_vault_secret.cd_azure_devops_pat.name
    key_vault_id = azurerm_key_vault.KeyVault.id   
  })
}