include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//resource_group"
}

inputs = {
  client_id           = get_env("TF_VAR_client_id")
  client_secret       = get_env("TF_VAR_client_secret")
  tenant_id           = get_env("TF_VAR_tenant_id")
  subscription_id     = get_env("TF_VAR_subscription_id")

  resource_group_name = "AmorRescate-dev"
  location             = "East US 2"
}
