data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_user" "users" {
  for_each = {
    for ra in distinct([
      for ra in var.container_role_assignments : 
      { key = "${ra.principal_type}-${ra.principal_name}", value = ra }
      if ra.principal_type == "User"
    ]) : ra.key => ra.value
  }
  user_principal_name = each.value.principal_name
}

data "azuread_group" "groups" {
  for_each = {
    for ra in distinct([
      for ra in var.container_role_assignments : 
      { key = "${ra.principal_type}-${ra.principal_name}", value = ra }
      if ra.principal_type == "Group"
    ]) : ra.key => ra.value
  }
  display_name = each.value.principal_name
}

data "azuread_service_principal" "sps" {
  for_each = {
    for ra in distinct([
      for ra in var.container_role_assignments : 
      { key = "${ra.principal_type}-${ra.principal_name}", value = ra }
      if ra.principal_type == "ServicePrincipal"
    ]) : ra.key => ra.value
  }
  display_name = each.value.principal_name
}