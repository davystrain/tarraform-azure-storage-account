locals {
  container_role_assignment_map = {
    for ra in var.container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => {
      scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${ra.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${ra.storage_account_name}/blobServices/default/containers/${ra.container_name}"
      role_definition_name = ra.role_definition_name
      principal_id = (
        ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id :
        ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id :
        ra.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[ra.principal_name].object_id :
        null
      )
    }
  }
  group_names = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "Group"
  ])

  user_names = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "User"
  ])

  sp_names = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "ServicePrincipal"
  ])
}