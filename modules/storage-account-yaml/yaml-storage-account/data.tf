data "azurerm_resource_group" "rg" {
  for_each = { for rg in local.storage_account_list : rg => rg }
  name     = each.key
}