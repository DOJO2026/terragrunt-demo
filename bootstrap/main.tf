# ==========================================================
# BOOTSTRAP - se corre UNA sola vez, manualmente, con backend
# LOCAL (no remoto), porque crea el propio backend remoto que
# después usará todo el resto del proyecto (Terragrunt).
#
# No se integra al árbol de environments/ ni a terragrunt.hcl
# a propósito: si lo hiciéramos, tendríamos la misma
# dependencia circular que estamos resolviendo.
# ==========================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Sin bloque "backend" -> usa backend local (terraform.tfstate en esta carpeta)
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "state_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "state_sa" {
  # Nombre debe ser único a nivel global en Azure (solo minúsculas/números, 3-24 chars)
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state_rg.name
  location                 = azurerm_resource_group.state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true # protege el .tfstate ante sobrescrituras accidentales
  }
}

resource "azurerm_storage_container" "state_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.state_sa.name
  container_access_type = "private"
}
