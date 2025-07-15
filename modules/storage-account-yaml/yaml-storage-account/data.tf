data "azuread_group" "lookup" {
  for_each     = local.group_names
  display_name = each.value
}

data "azuread_user" "lookup" {
  for_each            = local.user_names
  user_principal_name = each.value
}

data "azuread_service_principal" "lookup" {
  for_each     = local.sp_names
  display_name = each.value
}
