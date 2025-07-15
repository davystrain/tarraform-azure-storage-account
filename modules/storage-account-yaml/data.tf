data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

data "azuread_user" "users" {
  for_each = {
    for ra in var.container_role_assignments : "${ra.principal_type}-${ra.principal_name}" => ra
    if ra.principal_type == "User"
  }
  user_principal_name = each.value.principal_name
}

data "azuread_group" "groups" {
  for_each = {
    for ra in var.container_role_assignments : "${ra.principal_type}-${ra.principal_name}" => ra
    if ra.principal_type == "Group"
  }
  display_name = each.value.principal_name
}

data "azuread_service_principal" "sps" {
  for_each = {
    for ra in var.container_role_assignments : "${ra.principal_type}-${ra.principal_name}" => ra
    if ra.principal_type == "ServicePrincipal"
  }
  display_name = each.value.principal_name
}
