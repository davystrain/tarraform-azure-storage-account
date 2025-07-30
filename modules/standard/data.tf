data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_user" "users" {
  for_each            = local.user_principals # Uses the local we created
  user_principal_name = each.value
}

data "azuread_group" "groups" {
  for_each     = local.group_principals # Uses the local we created
  display_name = each.value
}

data "azuread_service_principal" "sps" {
  for_each     = local.sp_principals # Uses the local we created
  display_name = each.value
}

