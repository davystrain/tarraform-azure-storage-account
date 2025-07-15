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
        role_assignments                 = try(v.role_assignments, {})
      }
    ]
  ])

  storage_account_map = { for sa in local.storage_account_list : sa.storage_account_name => sa }

  # Create resource context for all assignable resources
  principal_assignments = flatten([
    for sa in local.storage_account_list : [
      # Storage account level assignments
      {
        resource_type    = "storage_account"
        resource_name    = sa.storage_account_name
        role_assignments = sa.role_assignments
      },
      # Container level assignments
      [for container in sa.containers : {
        resource_type    = "container"
        resource_name    = container.name
        role_assignments = try(container.role_assignments, {})
      }],
      # Blob level assignments
      [for blob in sa.blobs : {
        resource_type    = "blob"
        resource_name    = blob.name
        role_assignments = try(blob.role_assignments, {})
      }],
      # Queue level assignments
      [for queue in sa.queues : {
        resource_type    = "queue"
        resource_name    = queue.name
        role_assignments = try(queue.role_assignments, {})
      }],
      # Table level assignments
      [for table in sa.tables : {
        resource_type    = "table"
        resource_name    = table.name
        role_assignments = try(table.role_assignments, {})
      }]
    ]
  ])

  # Flatten all role assignments with proper resource context
  principal_assignments_flat = flatten([
    for pa in local.principal_assignments : [
      for principal_type, roles in pa.role_assignments : [
        for role, principals in roles : [
          for principal in principals : {
            key                  = "${pa.resource_type}-${pa.resource_name}-${role}-${principal}"
            resource_type        = pa.resource_type
            resource_name        = pa.resource_name
            principal_type       = principal_type
            role_definition_name = role
            principal_name       = principal
          }
        ]
      ]
    ]
  ])

  # Group assignments by principal type efficiently
  assignments_by_type = {
    for assignment in local.principal_assignments_flat :
    assignment.principal_type => assignment...
  }

  # Extract assignments and names by type
  group_assignments = {
    for assignment in try(local.assignments_by_type["Group"], []) :
    assignment.key => assignment
  }

  user_assignments = {
    for assignment in try(local.assignments_by_type["User"], []) :
    assignment.key => assignment
  }

  sp_assignments = {
    for assignment in try(local.assignments_by_type["ServicePrincipal"], []) :
    assignment.key => assignment
  }

  # Extract unique principal names for data source lookups
  group_names = toset([
    for assignment in try(local.assignments_by_type["Group"], []) :
    assignment.principal_name
  ])

  user_names = toset([
    for assignment in try(local.assignments_by_type["User"], []) :
    assignment.principal_name
  ])

  sp_names = toset([
    for assignment in try(local.assignments_by_type["ServicePrincipal"], []) :
    assignment.principal_name
  ])

  # Group assignments by storage account for passing to modules
  storage_account_assignments = {
    for sa_name in keys(local.storage_account_map) : sa_name => {
      group_assignments = {
        for k, v in local.group_assignments : k => v
        if v.resource_type == "storage_account" && v.resource_name == sa_name
      }
      user_assignments = {
        for k, v in local.user_assignments : k => v
        if v.resource_type == "storage_account" && v.resource_name == sa_name
      }
      sp_assignments = {
        for k, v in local.sp_assignments : k => v
        if v.resource_type == "storage_account" && v.resource_name == sa_name
      }
    }
  }

  # Enhanced storage account map with assignments
  storage_account_map_with_assignments = {
    for sa_name, sa_config in local.storage_account_map : sa_name => merge(sa_config, local.storage_account_assignments[sa_name])
  }
}