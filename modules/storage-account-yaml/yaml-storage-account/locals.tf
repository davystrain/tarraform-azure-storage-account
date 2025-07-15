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
        blob_properties                  = try(v.blob_properties, null)
        network_rules                    = try(v.network_rules, null)
        containers                       = try(v.containers, [])
        blobs                            = try(v.blobs, [])
        queues                           = try(v.queues, [])
        tables                           = try(v.tables, [])
        tags                             = try(v.tags, {})
      }
    ]
  ])
  storage_account_map = { for sa in local.storage_account_list : sa.storage_account_name => sa }

  role_assignments_flat = flatten([
    for sa in local.storage_account_list : [
      # Storage account level
      for principal_type, roles in try(sa.role_assignments, {}) : [
        for role, principals in roles : [
          for principal in principals : {
            resource_type        = "storage_account"
            resource_name        = sa.storage_account_name
            role_definition_name = role
            principal_id         = principal
          }
        ]
      ]
    ] +
    # Containers
    flatten([
      for container in sa.containers : [
        for principal_type, roles in try(container.role_assignments, {}) : [
          for role, principals in roles : [
            for principal in principals : {
              resource_type        = "container"
              resource_name        = container.name
              role_definition_name = role
              principal_id         = principal
            }
          ]
        ]
      ]
    ]) +
    # Blobs
    flatten([
      for blob in sa.blobs : [
        for principal_type, roles in try(blob.role_assignments, {}) : [
          for role, principals in roles : [
            for principal in principals : {
              resource_type        = "blob"
              resource_name        = blob.name
              role_definition_name = role
              principal_id         = principal
            }
          ]
        ]
      ]
    ]) +
    # Queues
    flatten([
      for queue in sa.queues : [
        for principal_type, roles in try(queue.role_assignments, {}) : [
          for role, principals in roles : [
            for principal in principals : {
              resource_type        = "queue"
              resource_name        = queue.name
              role_definition_name = role
              principal_id         = principal
            }
          ]
        ]
      ]
    ]) +
    # Tables
    flatten([
      for table in sa.tables : [
        for principal_type, roles in try(table.role_assignments, {}) : [
          for role, principals in roles : [
            for principal in principals : {
              resource_type        = "table"
              resource_name        = table.name
              role_definition_name = role
              principal_id         = principal
            }
          ]
        ]
      ]
    ])
  ])
  role_assignments_map = { for idx, ra in local.role_assignments_flat : "${ra.resource_type}-${ra.resource_name}-${ra.role_definition_name}-${ra.principal_id}" => ra }
}