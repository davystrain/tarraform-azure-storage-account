locals {
  # Only YAML parsing - no hardcoded logic needed
  storage_account_map = merge([
    for file in fileset(var.yaml_config_path, "*.{yaml,yml}") : {
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")).storage_accounts : k => {
        storage_account_name             = k
        resource_group_name              = v.resource_group_name
        location                         = v.location
        access_tier                      = v.access_tier
        account_replication_type         = v.account_replication_type
        account_tier                     = v.account_tier
        account_kind                     = try(v.account_kind, "StorageV2")
        allow_nested_items_to_be_public  = try(v.allow_nested_items_to_be_public, false)
        cross_tenant_replication_enabled = try(v.cross_tenant_replication_enabled, false)
        default_to_oauth_authentication  = try(v.default_to_oauth_authentication, true)
        https_traffic_only_enabled       = try(v.https_traffic_only_enabled, true)
        min_tls_version                  = try(v.min_tls_version, "TLS1_2")
        public_network_access_enabled    = try(v.public_network_access_enabled, false)
        shared_access_key_enabled        = try(v.shared_access_key_enabled, false)
        local_user_enabled               = try(v.local_user_enabled, false)
        containers                       = try(v.containers, [])
        queues                           = try(v.queues, [])
        tables                           = try(v.tables, [])
        tags                             = try(v.tags, {})

        # Flatten role assignments during YAML parsing
        container_role_assignments = flatten([
          for container in try(v.containers, []) : [
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
      }
    }
  ]...)

  # Direct role assignment creation (no hardcoded merge needed)
  container_role_assignments = merge([
    for sa_name, sa_config in local.storage_account_map : {
      for ra in try(sa_config.container_role_assignments, []) :
      "${sa_name}-${ra.container_name}-${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}" => {
        scope                = azurerm_storage_container.containers["${sa_name}-${ra.container_name}"].resource_manager_id
        role_definition_name = ra.role_definition_name
        principal_id = (
          ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id :
          ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id :
          ra.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[ra.principal_name].object_id :
          null
        )
      }
    }
  ]...)
}