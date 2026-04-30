resource "azurerm_storage_account" "sa" {
  name                              = var.name
  resource_group_name               = data.azurerm_resource_group.rg.name
  location                          = var.location
  access_tier                       = var.access_tier
  account_replication_type          = var.account_replication_type
  account_tier                      = var.account_tier
  account_kind                      = var.account_kind
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  default_to_oauth_authentication   = var.default_to_oauth_authentication
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  min_tls_version                   = var.min_tls_version
  public_network_access_enabled     = var.public_network_access_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  local_user_enabled                = var.local_user_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  tags                              = merge(var.tags, data.azurerm_resource_group.rg.tags)

  lifecycle {
    ignore_changes = [
      # Ignore tags set by Azure Policy
      # https://github.com/racwa/azure-policy/blob/main/data/policy-set-definitions/inherit-tags-from-subscription.json
      tags["Company"],
      tags["BusinessUnit"],
      tags["Department"],
      tags["CostCentre"],
      tags["BusinessService"],
      tags["Environment"],
    ]
  }

  dynamic "blob_properties" {
    for_each = var.blob_properties == null ? [] : [var.blob_properties]
    content {
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled
      versioning_enabled            = blob_properties.value.versioning_enabled

      container_delete_retention_policy {
        days = blob_properties.value.container_delete_retention_policy.days
      }

      delete_retention_policy {
        days                     = blob_properties.value.delete_retention_policy.days
        permanent_delete_enabled = blob_properties.value.delete_retention_policy.permanent_delete_enabled
      }

      restore_policy {
        days = blob_properties.value.restore_policy.days
      }

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rules == null ? [] : blob_properties.value.cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      bypass                     = network_rules.value.bypass
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access == null ? [] : network_rules.value.private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = coalesce(private_link_access.value.endpoint_tenant_id, data.azurerm_client_config.current.tenant_id)
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website == true ? [1] : []
    content {
      index_document = var.static_website_index_document
    }
  }
}

resource "azurerm_storage_container" "sc" {
  for_each           = { for c in var.containers : c.name => c }
  name               = each.value.name
  storage_account_id = azurerm_storage_account.sa.id
}

resource "azurerm_storage_management_policy" "mp" {
  count              = length(local.management_policy_rules) > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.sa.id

  dynamic "rule" {
    for_each = local.management_policy_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        blob_types   = rule.value.filters.blob_types
        prefix_match = rule.value.filters.prefix_match
      }

      actions {
        dynamic "base_blob" {
          for_each = try(rule.value.actions.base_blob, null) == null ? [] : [rule.value.actions.base_blob]
          content {
            delete_after_days_since_modification_greater_than              = base_blob.value.delete_after_days_since_modification_greater_than
            delete_after_days_since_last_access_time_greater_than          = base_blob.value.delete_after_days_since_last_access_time_greater_than
            delete_after_days_since_creation_greater_than                  = base_blob.value.delete_after_days_since_creation_greater_than
            tier_to_cool_after_days_since_modification_greater_than        = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            tier_to_cool_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cool_after_days_since_last_access_time_greater_than
            tier_to_cool_after_days_since_creation_greater_than            = base_blob.value.tier_to_cool_after_days_since_creation_greater_than
            tier_to_cold_after_days_since_modification_greater_than        = base_blob.value.tier_to_cold_after_days_since_modification_greater_than
            tier_to_cold_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cold_after_days_since_last_access_time_greater_than
            tier_to_cold_after_days_since_creation_greater_than            = base_blob.value.tier_to_cold_after_days_since_creation_greater_than
            tier_to_archive_after_days_since_modification_greater_than     = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
            tier_to_archive_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_archive_after_days_since_last_access_time_greater_than
            tier_to_archive_after_days_since_creation_greater_than         = base_blob.value.tier_to_archive_after_days_since_creation_greater_than
            tier_to_archive_after_days_since_last_tier_change_greater_than = base_blob.value.tier_to_archive_after_days_since_last_tier_change_greater_than
          }
        }

        dynamic "snapshot" {
          for_each = try(rule.value.actions.snapshot, null) == null ? [] : [rule.value.actions.snapshot]
          content {
            delete_after_days_since_creation_greater_than                  = snapshot.value.delete_after_days_since_creation_greater_than
            change_tier_to_archive_after_days_since_creation               = snapshot.value.change_tier_to_archive_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = snapshot.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            change_tier_to_cool_after_days_since_creation                  = snapshot.value.change_tier_to_cool_after_days_since_creation
            tier_to_cold_after_days_since_creation_greater_than            = snapshot.value.tier_to_cold_after_days_since_creation_greater_than
          }
        }

        dynamic "version" {
          for_each = try(rule.value.actions.version, null) == null ? [] : [rule.value.actions.version]
          content {
            delete_after_days_since_creation                               = version.value.delete_after_days_since_creation
            change_tier_to_archive_after_days_since_creation               = version.value.change_tier_to_archive_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = version.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            change_tier_to_cool_after_days_since_creation                  = version.value.change_tier_to_cool_after_days_since_creation
            tier_to_cold_after_days_since_creation_greater_than            = version.value.tier_to_cold_after_days_since_creation_greater_than
          }
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "container_roles" {
  for_each = local.container_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  depends_on           = [azurerm_storage_account.sa, azurerm_storage_container.sc]
}

resource "azapi_resource" "sq" {
  for_each  = { for q in var.queues : q.name => q }
  type      = "Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01"
  name      = each.value.name
  parent_id = "${azurerm_storage_account.sa.id}/queueServices/default"
  body = {
    properties = try(each.value.properties, {})
  }
}

resource "azapi_resource" "st" {
  for_each  = { for t in var.tables : t.name => t }
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  name      = each.value.name
  parent_id = "${azurerm_storage_account.sa.id}/tableServices/default"
  body = {
    properties = try(each.value.properties, {})
  }
}

resource "azurerm_private_endpoint" "blob" {
  name                          = "pe-blob-${var.name}"
  location                      = data.azurerm_resource_group.rg.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
  custom_network_interface_name = "pe-blob-${var.name}-nic"
  tags                          = merge(var.tags, data.azurerm_resource_group.rg.tags)

  lifecycle {
    ignore_changes = [
      # Ignore tags set by Azure Policy
      # https://github.com/racwa/azure-policy/blob/main/data/policy-set-definitions/inherit-tags-from-subscription.json
      tags["Company"],
      tags["BusinessUnit"],
      tags["Department"],
      tags["CostCentre"],
      tags["BusinessService"],
      tags["Environment"],
    ]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_blob_azure_net.id]
  }

  private_service_connection {
    name                           = "pe-blob-${var.name}-psc"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

# Private DNS zones do not exist for these 2 resource blocks yet
# resource "azurerm_private_endpoint" "queue" {
#   name                          = "pe-queue-${var.name}"
#   location                      = data.azurerm_resource_group.rg.location
#   resource_group_name           = data.azurerm_resource_group.rg.name
#   subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
#   custom_network_interface_name = "pe-queue-${var.name}-nic"
#   tags                          = merge(data.azurerm_resource_group.rg.tags, var.tags)

#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_queue_azure_net.id]
#   }

#   private_service_connection {
#     name                           = "pe-queue-${var.name}-psc"
#     private_connection_resource_id = azurerm_storage_account.sa.id
#     subresource_names              = ["queue"]
#     is_manual_connection           = false
#   }
# }
# resource "azurerm_private_endpoint" "table" {
#   name                          = "pe-table-${var.name}"
#   location                      = data.azurerm_resource_group.rg.location
#   resource_group_name           = data.azurerm_resource_group.rg.name
#   subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
#   custom_network_interface_name = "pe-table-${var.name}-nic"
#   tags                          = merge(data.azurerm_resource_group.rg.tags, var.tags)

#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_table_azure_net.id]
#   }

#   private_service_connection {
#     name                           = "pe-table-${var.name}-psc"
#     private_connection_resource_id = azurerm_storage_account.sa.id
#     subresource_names              = ["table"]
#     is_manual_connection           = false
# }

resource "azurerm_role_assignment" "resource_role_assignment" {
  for_each = {
    for assignment in local.resource_rbac_assignments_lookup :
    "${assignment.identity_type}-${replace(assignment.role_definition_name, " ", "-")}-${assignment.principal_id}" => assignment
  }
  scope                = azurerm_storage_account.sa.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
# }
