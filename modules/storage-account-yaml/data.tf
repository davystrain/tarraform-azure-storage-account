data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  for_each = toset([
    for sa_name, sa_config in local.storage_account_map : sa_config.resource_group_name
  ])
  name = each.key
}

# Azure AD data sources for all role assignments
data "azuread_user" "users" {
  for_each = toset([
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "User"
  ])
  user_principal_name = each.key
}

data "azuread_group" "groups" {
  for_each = toset([
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "Group"
  ])
  display_name = each.key
}

data "azuread_service_principal" "sps" {
  for_each = toset([
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "ServicePrincipal"
  ])
  display_name = each.key
}