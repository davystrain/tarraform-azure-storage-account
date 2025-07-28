locals {
  # YAML parsing logic
  storage_account_map = merge([
    for file in fileset(var.yaml_config_path, "*.{yaml,yml}") : {
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")).storage_accounts : k => {
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
        queues                           = try(v.queues, [])
        tables                           = try(v.tables, [])
        tags                             = try(v.tags, {})
      }
    }
  ]...)

  # Flatten all role assignments from all storage accounts
  all_role_assignments = flatten([
    for sa_name, sa_config in local.storage_account_map : [
      for container in try(sa_config.containers, []) : [
        for principal_type, roles in try(container.role_assignments, {}) : [
          for role_definition_name, principal_names in roles : [
            for principal_name in principal_names : {
              storage_account_name = sa_name
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

  # Create role assignments with Azure resource references
  container_role_assignments = {
    for ra in local.all_role_assignments :
    "${ra.storage_account_name}-${ra.container_name}-${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}" => {
      scope                = azurerm_storage_container.containers["${ra.storage_account_name}-${ra.container_name}"].resource_manager_id
      role_definition_name = ra.role_definition_name
      principal_id = (
        ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id :
        ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id :
        ra.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[ra.principal_name].object_id :
        null
      )
    }
  }
}