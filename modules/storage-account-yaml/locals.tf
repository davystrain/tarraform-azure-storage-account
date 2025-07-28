locals {
  storage_account_map = {
    for k, v in var.yaml_config_path.storage : k => {
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

  container_role_assignments = merge([
    for sa_name, sa_config in local.storage_account_map : {
      for ra in try(sa_config.container_role_assignments, []) :
      "${sa_name}-${ra.container_name}-${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}" => {
        storage_account_name = sa_name
        container_name       = ra.container_name
        principal_type       = ra.principal_type
        principal_name       = ra.principal_name
        role_definition_name = ra.role_definition_name
      }
    }
  ]...)
}
