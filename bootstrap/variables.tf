variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "rg-terraform-state"
}

variable "location" {
  type    = string
  default = "East US 2"
}

variable "storage_account_name" {
  description = "Debe ser único global en Azure. Solo minúsculas y números, 3-24 caracteres."
  type        = string
}

variable "container_name" {
  type    = string
  default = "tfstate"
}
