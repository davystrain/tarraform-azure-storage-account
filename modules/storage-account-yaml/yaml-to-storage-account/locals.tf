locals {
  storage_account_files = fileset(var.yaml_config_path, "*.{yaml,yml}")

  storage_account_list = flatten([
    for file in local.storage_account_files : [
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")).storage_accounts : {
        storage_account_name             = k
        resource_group_name              = v.resource_group_name
        location                         = v.location
        access_tier                      = v.access_tier
        account_replication_type         = v.account_replication_type
        account_tier                     = v.account_tier
        account_kind                     = try(v.account_kind, null)
        allow_nested_items_to_be_public  = try(v.allow_nested_items_to_be_public, null)
        cross_tenant_replication_enabled = try(v.cross_tenant_replication_enabled, null)
        default_to_oauth_authentication  = try(v.default_to_oauth_authentication, null)
        https_traffic_only_enabled       = try(v.https_traffic_only_enabled, null)
        min_tls_version                  = try(v.min_tls_version, null)
        public_network_access_enabled    = try(v.public_network_access_enabled, null)
        shared_access_key_enabled        = try(v.shared_access_key_enabled, null)
        local_user_enabled               = try(v.local_user_enabled, null)
        containers                       = try(v.containers, [])
        tags                             = try(v.tags, {})
      }
    ]
  ])

  storage_account_map = { for sa in local.storage_account_list : sa.storage_account_name => sa }

  container_role_assignments = flatten([
    for sa in local.storage_account_list : [
      for container in try(sa.containers, []) : [
        for principal_type, roles in try(container.role_assignments, {}) : [
          for role_definition_name, principal_names in roles : [
            for principal_name in principal_names : {
              storage_account_name = sa.storage_account_name
              resource_group_name  = sa.resource_group_name
              container_name       = container.name
              principal_type       = principal_type
              role_definition_name = role_definition_name
              principal_name       = principal_name
            }
          ]
        ]
      ]
    ]
  ])

  container_role_assignments_map = {
    for sa in local.storage_account_list :
    sa.storage_account_name => [
      for ra in local.container_role_assignments :
      ra if ra.storage_account_name == sa.storage_account_name
    ]
  }

  container_role_assignment_map = {
    for ra in local.container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => {
      scope                = var.storage_container_ids[ra.container_name]
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
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "Group"
  ])

  user_names = toset([
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "User"
  ])

  sp_names = toset([
    for ra in local.container_role_assignments : ra.principal_name
    if ra.principal_type == "ServicePrincipal"
  ])
}
