include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//app_service"
}

dependency "resource_group" {
  config_path = "../resource_group"

  mock_outputs = {
    name     = "mock-rg"
    location = "East US 2"
  }
}

inputs = {
  client_id       = get_env("TF_VAR_client_id")
  client_secret   = get_env("TF_VAR_client_secret")
  tenant_id       = get_env("TF_VAR_tenant_id")
  subscription_id = get_env("TF_VAR_subscription_id")

  app_service_name    = "amorrescate-qa"
  resource_group_name = dependency.resource_group.outputs.name
  location             = dependency.resource_group.outputs.location
  sku_name             = "F1"
}
