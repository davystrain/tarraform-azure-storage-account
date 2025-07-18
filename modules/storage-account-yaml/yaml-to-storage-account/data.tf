data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  for_each = local.storage_account_files.resource_group_name
  name     = each.value
}
data "azuread_user" "users" {
  for_each            = local.user_names
  user_principal_name = each.value
}

data "azuread_group" "groups" {
  for_each     = local.group_names
  display_name = each.value
}

data "azuread_service_principal" "sps" {
  for_each     = local.sp_names
  display_name = each.value
}
