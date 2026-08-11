# ==========================================================
# ROOT terragrunt.hcl
# Config compartida por TODOS los módulos y ambientes.
# Esto es lo que en Terraform puro tendrías que copiar/pegar
# en cada environment (backend + provider).
# ==========================================================

locals {
  # Config común a todos los ambientes (se puede sobreescribir por env)
  common_vars = {
    project = "ProyectoCloudComputing"
  }
}

# ------------------------------------------------------------
# Backend remoto DRY: se genera automáticamente para cada
# módulo hijo, usando el path del módulo para separar el
# state key. Antes: sin backend remoto, state local por módulo.
# ------------------------------------------------------------
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstateprojectcc" # debe existir previamente
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# ------------------------------------------------------------
# Provider DRY: se genera automáticamente en cada módulo hijo.
# En tu main.tf actual, este bloque solo existe una vez porque
# todo está en un archivo. En cuanto separas en módulos con
# Terraform puro, tendrías que repetirlo en cada uno.
# ------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
EOF
}

# Inputs disponibles para todos los módulos que incluyan este root
inputs = {
  project = local.common_vars.project
}
