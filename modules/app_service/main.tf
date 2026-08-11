resource "azurerm_service_plan" "plan" {
  name                = "${var.app_service_name}-plan"
  resource_group_name = var.resource_group_name
  location             = var.location
  os_type             = "Windows"
  sku_name            = var.sku_name
}

resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location             = var.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      dotnet_version = "v8.0"
      current_stack  = "dotnet"
    }
  }
}
