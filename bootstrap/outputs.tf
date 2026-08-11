output "resource_group_name" {
  value = azurerm_resource_group.state_rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.state_sa.name
}

output "container_name" {
  value = azurerm_storage_container.state_container.name
}

output "resumen_para_terragrunt_hcl" {
  value = <<EOT

  Copia esto al bloque remote_state.config del terragrunt.hcl raíz:

  resource_group_name  = "${azurerm_resource_group.state_rg.name}"
  storage_account_name = "${azurerm_storage_account.state_sa.name}"
  container_name        = "${azurerm_storage_container.state_container.name}"
EOT
}
