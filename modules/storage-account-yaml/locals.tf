locals {
  container_role_assignment_objects = {
    for ra in var.container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => ra
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
