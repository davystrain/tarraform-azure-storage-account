data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "rg" {
  for_each = { for resource_group_name in local.storage_account_list : rg => rg }
  name     = each.key
}