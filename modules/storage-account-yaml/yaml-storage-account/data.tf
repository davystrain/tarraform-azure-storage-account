data "azurerm_resource_group" "rg" {
  for_each = { for sa in local.storage_account_list : sa.resource_group_name => sa }
  name     = each.key
}