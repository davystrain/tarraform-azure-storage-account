data "azurerm_client_config" "current" {}

data "resource_group" "rg" {
  name = var.resource_group_name
}