data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  for_each = toset([
    for sa_config in local.storage_account_map : sa_config.resource_group_name
  ])
  name = each.value
}

data "azuread_user" "users" {
  for_each = toset([
    for v in values(local.container_role_assignments) : v.principal_name
    if v.principal_type == "User"
  ])
  user_principal_name = each.value
}

data "azuread_group" "groups" {
  for_each = toset([
    for v in values(local.container_role_assignments) : v.principal_name
    if v.principal_type == "Group"
  ])
  display_name = each.value
}

data "azuread_service_principal" "sps" {
  for_each = toset([
    for v in values(local.container_role_assignments) : v.principal_name
    if v.principal_type == "ServicePrincipal"
  ])
  display_name = each.value
}
