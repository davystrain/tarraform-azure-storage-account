locals {
  storage_account_map = merge([
    for file in fileset(var.yaml_config_path, "*.{yaml,yml}") : {
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")) : k => {
        storage_account_name              = k
        resource_group_name               = v.resource_group_name
        account_replication_type          = try(v.account_replication_type, "LRS")
        account_tier                      = try(v.account_tier, "Standard")
        access_tier                       = try(v.access_tier, "Hot")
        account_kind                      = try(v.account_kind, "StorageV2")
        allow_nested_items_to_be_public   = try(v.allow_nested_items_to_be_public, false)
        cross_tenant_replication_enabled  = try(v.cross_tenant_replication_enabled, false)
        default_to_oauth_authentication   = try(v.default_to_oauth_authentication, true)
        https_traffic_only_enabled        = try(v.https_traffic_only_enabled, true)
        min_tls_version                   = try(v.min_tls_version, "TLS1_2")
        public_network_access_enabled     = try(v.public_network_access_enabled, true)
        shared_access_key_enabled         = try(v.shared_access_key_enabled, false)
        local_user_enabled                = try(v.local_user_enabled, false)
        infrastructure_encryption_enabled = try(v.infrastructure_encryption_enabled, true)
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