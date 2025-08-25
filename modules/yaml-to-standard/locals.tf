locals {
  storage_account_map = merge([
    for file in fileset(var.yaml_config_path, "*.{yaml,yml}") : {
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")) : k => {
        storage_account_name              = k
        resource_group_name               = v.resource_group_name
        location                          = coalesce(try(v.location, null), "australiaeast")
        account_replication_type          = coalesce(try(v.account_replication_type, null), "LRS")
        account_tier                      = coalesce(try(v.account_tier, null), "Standard")
        access_tier                       = coalesce(try(v.access_tier, null), "Hot")
        account_kind                      = coalesce(try(v.account_kind, null), "StorageV2")
        allow_nested_items_to_be_public   = coalesce(try(v.allow_nested_items_to_be_public, null), false)
        cross_tenant_replication_enabled  = coalesce(try(v.cross_tenant_replication_enabled, null), false)
        default_to_oauth_authentication   = coalesce(try(v.default_to_oauth_authentication, null), true)
        https_traffic_only_enabled        = coalesce(try(v.https_traffic_only_enabled, null), true)
        min_tls_version                   = coalesce(try(v.min_tls_version, null), "TLS1_2")
        public_network_access_enabled     = coalesce(try(v.public_network_access_enabled, null), true)
        shared_access_key_enabled         = coalesce(try(v.shared_access_key_enabled, null), false)
        local_user_enabled                = coalesce(try(v.local_user_enabled, null), false)
        infrastructure_encryption_enabled = coalesce(try(v.infrastructure_encryption_enabled, null), true)
        blob_properties                   = try(v.blob_properties, {})
        network_rules                     = try(v.network_rules, {})
        containers                        = try(v.containers, [])
        queues                            = try(v.queues, [])
        tables                            = try(v.tables, [])
        tags                              = try(v.tags, {})

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
}