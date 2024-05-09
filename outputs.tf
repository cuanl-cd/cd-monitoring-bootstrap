output "commands" {
  value = var.rbac ? null : <<-EOF

  az role assignment create --assignee ${azurerm_user_assigned_identity.github.principal_id} --role "Deployment Stacks Contributor" \
    --scope ${azurerm_resource_group.rg.id}

  az role assignment create --assignee ${azurerm_user_assigned_identity.github.principal_id} --role "Monitoring Contributor" \
    --scope ${azurerm_resource_group.rg.id}

  az role assignment create --assignee ${azurerm_user_assigned_identity.github.principal_id} --role "Storage Blob Data Contributor" \
    --scope ${azurerm_resource_group.rg.id}

  az role assignment create --assignee ${azurerm_user_assigned_identity.github.principal_id} --role "Contributor" \
    --scope ${var.workspace_id}

  EOF
}
