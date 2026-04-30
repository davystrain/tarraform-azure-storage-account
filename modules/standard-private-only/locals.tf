locals {
  container_role_assignments = {
    for ra in var.container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => {
      scope                = azurerm_storage_container.sc[ra.container_name].resource_manager_id
      role_definition_name = ra.role_definition_name
      principal_id = (
        ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id :
        ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id :
        ra.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[ra.principal_name].object_id :
        null
      )
    }
  }

  resource_rbac_assignments = flatten([
    for identity_type, roles in var.resource_role_assignments : flatten([
      for role_definition, principals in coalesce(roles, {}) : [
        for principal in principals : {
          identity_type        = identity_type
          role_definition_name = role_definition
          principal_lookup     = principal
        }
      ]
    ])
  ])

  # Combine all principals from both container and resource assignments for data source lookups
  all_rbac_assignments = concat(
    [for ra in var.container_role_assignments : {
      identity_type    = ra.principal_type
      principal_lookup = ra.principal_name
    }],
    local.resource_rbac_assignments
  )

  group_names = toset([
    for a in local.all_rbac_assignments : a.principal_lookup
    if a.identity_type == "Group"
  ])

  user_names = toset([
    for a in local.all_rbac_assignments : a.principal_lookup
    if a.identity_type == "User"
  ])

  sp_names = toset([
    for a in local.all_rbac_assignments : a.principal_lookup
    if a.identity_type == "ServicePrincipal"
  ])

  resource_rbac_assignments_lookup = [
    for assignment in local.resource_rbac_assignments : merge(assignment, {
      principal_id = (
        assignment.identity_type == "Group" ? data.azuread_group.groups[assignment.principal_lookup].object_id :
        assignment.identity_type == "User" ? data.azuread_user.users[assignment.principal_lookup].object_id :
        assignment.identity_type == "ServicePrincipal" ? data.azuread_service_principal.sps[assignment.principal_lookup].object_id :
        null
      )
    })
  ]

  # Flatten lifecycle rules from all containers into a single list for the management policy resource.
  # Rule names are prefixed with the container name to guarantee uniqueness across all containers.
  # prefix_match entries describe paths *within* the container; the module prepends the container
  # name automatically so callers never need to know about Azure's storage-path convention.
  management_policy_rules = flatten([
    for container in var.containers : [
      for rule in try(container.lifecycle_rules, []) : {
        name    = "${container.name}-${rule.name}"
        enabled = try(rule.enabled, true)
        filters = {
          blob_types = try(rule.filters.blob_types, ["blockBlob"])
          prefix_match = length(try(rule.filters.prefix_match, [])) > 0 ? (
            [for p in rule.filters.prefix_match : "${container.name}/${p}"]
          ) : ["${container.name}/"]
        }
        actions = rule.actions
      }
    ]
  ])
}
