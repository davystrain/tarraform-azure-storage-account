data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_user" "users" {
  for_each = {
    for key in toset([
      for ra in var.container_role_assignments :
      "${ra.principal_type}-${ra.principal_name}"
      if ra.principal_type == "User"
    ]) :
    key => {
      principal_name = split("-", key)[1]
    }
  }
  user_principal_name = each.value.principal_name
}

data "azuread_group" "groups" {
  for_each = {
    for key in toset([
      for ra in var.container_role_assignments :
      "${ra.principal_type}-${ra.principal_name}"
      if ra.principal_type == "Group"
    ]) :
    key => {
      principal_name = split("-", key)[1]
    }
  }
  display_name = each.value.principal_name
}

data "azuread_service_principal" "sps" {
  for_each = {
    for key in toset([
      for ra in var.container_role_assignments :
      "${ra.principal_type}-${ra.principal_name}"
      if ra.principal_type == "ServicePrincipal"
    ]) :
    key => {
      principal_name = split("-", key)[1]
    }
  }
  display_name = each.value.principal_name
}
