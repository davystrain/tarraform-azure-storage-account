resource "azurerm_storage_account" "reusable_module" {
  name                             = var.name
  resource_group_name              = data.azurerm_resource_group.rg.name
  location                         = data.azurerm_resource_group.rg.location
  access_tier                      = var.access_tier
  account_replication_type         = var.account_replication_type
  account_tier                     = var.account_tier
  account_kind                     = var.account_kind
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  default_to_oauth_authentication  = var.default_to_oauth_authentication
  https_traffic_only_enabled       = var.https_traffic_only_enabled
  min_tls_version                  = var.min_tls_version
  public_network_access_enabled    = var.public_network_access_enabled
  shared_access_key_enabled        = var.shared_access_key_enabled
  local_user_enabled               = var.local_user_enabled
  tags                             = merge(data.azurerm_resource_group.rg.tags, var.tags)
  # dynamic "blob_properties" {
  #   for_each = var.blob_properties == null ? [] : [var.blob_properties]
  #   content {
  #     change_feed_enabled           = blob_properties.value.change_feed_enabled
  #     change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
  #     default_service_version       = blob_properties.value.default_service_version
  #     last_access_time_enabled      = blob_properties.value.last_access_time_enabled
  #     versioning_enabled            = blob_properties.value.versioning_enabled

  #     container_delete_retention_policy {
  #       days = blob_properties.value.container_delete_retention_policy.days
  #     }

  #     delete_retention_policy {
  #       days                     = blob_properties.value.delete_retention_policy.days
  #       permanent_delete_enabled = blob_properties.value.delete_retention_policy.permanent_delete_enabled
  #     }

  #     restore_policy {
  #       days = blob_properties.value.restore_policy.days
  #     }
  #   }
  # }


  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      bypass                     = network_rules.value.bypass
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }
}

resource "azurerm_storage_container" "reusable_module" {
  count                 = length(var.containers)
  name                  = var.containers[count.index].name
  storage_account_id    = azurerm_storage_account.reusable_module.id
  container_access_type = var.containers[count.index].container_access_type
}

# resource "azurerm_storage_blob" "reusable_module" {
#   count                  = length(var.blobs)
#   name                   = var.blobs[count.index].name
#   storage_account_name   = azurerm_storage_account.reusable_module.name
#   storage_container_name = var.blobs[count.index].storage_container_name
#   type                   = var.blobs[count.index].type
#   depends_on = [ azurerm_storage_container.reusable_module ]
# }

# resource "azurerm_storage_queue" "reusable_module" {
#   count                = length(var.queues)
#   name                 = var.queues[count.index].name
#   storage_account_name = azurerm_storage_account.reusable_module.name
# }

# resource "azapi_resource" "reusable_module_table" {
#   count     = length(var.tables)
#   type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
#   name      = var.tables[count.index].name
#   parent_id = "${azurerm_storage_account.reusable_module.id}/tableServices/default"
#   body = {
#     properties = var.tables[count.index].properties
#   }
# }

resource "azurerm_role_assignment" "container_roles" {
  for_each = {
    for ra in var.container_role_assignments :
    "${ra.principal_type}-${ra.principal_name}-${ra.role_definition_name}-${ra.container_name}" => ra
  }

  scope = azurerm_storage_container.reusable_module[
    index(
      var.containers[*].name,
      each.value.container_name
    )
  ].resource_manager_id

  role_definition_name = each.value.role_definition_name

  principal_id = (
    each.value.principal_type == "User" ? data.azuread_user.users[each.value.principal_name].object_id :
    each.value.principal_type == "Group" ? data.azuread_group.groups[each.value.principal_name].object_id :
    each.value.principal_type == "ServicePrincipal" ? data.azuread_service_principal.sps[each.value.principal_name].object_id :
    null
  )

  depends_on = [azurerm_storage_container.reusable_module]
}
