locals {
  # Extract and flatten role assignments from containers
  flattened_container_role_assignments = flatten([
    for container in var.containers : [
      for principal_type, roles in try(container.role_assignments, {}) : [
        for role_definition_name, principal_names in roles : [
          for principal_name in principal_names : {
            container_name       = container.name
            principal_type       = principal_type
            role_definition_name = role_definition_name
            principal_name       = principal_name
          }
        ]
      ]
    ]
  ])

  # Create role assignments map for azurerm_role_assignment resources
  container_role_assignments = {
    for ra in local.flattened_container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => {
      scope                = azurerm_storage_container.reusable_module[ra.container_name].resource_manager_id
      role_definition_name = ra.role_definition_name
      principal_id = (
        ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id :
        ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id :
        ra.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[ra.principal_name].object_id :
        null
      )
    }
  }
  
  # Extract unique principal names for data source lookups
  user_principals = toset([
    for ra in local.flattened_container_role_assignments : ra.principal_name
    if ra.principal_type == "User"
  ])
  
  group_principals = toset([
    for ra in local.flattened_container_role_assignments : ra.principal_name
    if ra.principal_type == "Group"
  ])
  
  sp_principals = toset([
    for ra in local.flattened_container_role_assignments : ra.principal_name
    if ra.principal_type == "ServicePrincipal"
  ])
}