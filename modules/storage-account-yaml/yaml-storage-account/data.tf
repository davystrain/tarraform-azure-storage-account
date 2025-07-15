data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "rg" {
  for_each = toset([for sa in local.storage_account_list : sa.resource_group_name])
  name     = each.value
}