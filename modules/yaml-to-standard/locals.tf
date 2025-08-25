locals {
  storage_account_map = merge([
    for file in fileset(var.yaml_config_path, "*.{yaml,yml}") : {
      for k, v in yamldecode(file("${var.yaml_config_path}/${file}")) : k => {
        storage_account_name              = k
        resource_group_name               = v.resource_group_name
        location                          = v.location
        account_replication_type          = v.account_replication_type
        account_tier                      = v.account_tier
        access_tier                       = try(v.access_tier, null)
        account_kind                      = try(v.account_kind, null)
        allow_nested_items_to_be_public   = try(v.allow_nested_items_to_be_public, null)
        cross_tenant_replication_enabled  = try(v.cross_tenant_replication_enabled, null)
        default_to_oauth_authentication   = try(v.default_to_oauth_authentication, null)
        https_traffic_only_enabled        = try(v.https_traffic_only_enabled, null)
        min_tls_version                   = try(v.min_tls_version, null)
        public_network_access_enabled     = try(v.public_network_access_enabled, null)
        shared_access_key_enabled         = try(v.shared_access_key_enabled, null)
        local_user_enabled                = try(v.local_user_enabled, null)
        infrastructure_encryption_enabled = try(v.infrastructure_encryption_enabled, null)
        blob_properties                   = try(v.blob_properties, null)
        network_rules                     = try(v.network_rules, null)
        containers                        = try(v.containers, null)
        queues                            = try(v.queues, null)
        tables                            = try(v.tables, null)
        tags                              = try(v.tags, null)

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