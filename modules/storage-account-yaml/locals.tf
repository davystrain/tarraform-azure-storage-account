locals {
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
