resource "azurerm_role_assignment" "container_roles" {
  for_each = local.container_role_assignment_map

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}