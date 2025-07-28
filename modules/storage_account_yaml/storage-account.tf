resource "azurerm_storage_account" "reusable_module" {
  for_each = local.storage_account_map

  name                             = each.value.storage_account_name
  resource_group_name              = data.azurerm_resource_group.rg[each.value.resource_group_name].name
  location                         = each.value.location
  access_tier                      = each.value.access_tier
  account_replication_type         = each.value.account_replication_type
  account_tier                     = each.value.account_tier
  account_kind                     = each.value.account_kind
  allow_nested_items_to_be_public  = each.value.allow_nested_items_to_be_public
  cross_tenant_replication_enabled = each.value.cross_tenant_replication_enabled
  default_to_oauth_authentication  = each.value.default_to_oauth_authentication
  https_traffic_only_enabled       = each.value.https_traffic_only_enabled
  min_tls_version                  = each.value.min_tls_version
  public_network_access_enabled    = each.value.public_network_access_enabled
  shared_access_key_enabled        = each.value.shared_access_key_enabled
  local_user_enabled               = each.value.local_user_enabled
  tags                             = merge(data.azurerm_resource_group.rg[each.value.resource_group_name].tags, each.value.tags)
}

resource "azurerm_storage_container" "reusable_module" {
  for_each = {
    for key, container in flatten([
      for sa_name, sa_config in local.storage_account_map : [
        for container in sa_config.containers : {
          key                  = "${sa_name}-${container.name}"
          storage_account_name = sa_name
          container_name       = container.name
        }
      ]
    ]) : container.key => container
  }

  name               = each.value.container_name
  storage_account_id = azurerm_storage_account.reusable_module[each.value.storage_account_name].id
}

resource "azurerm_role_assignment" "container_roles" {
  for_each = {
    for key, ra in local.container_role_assignments : key => merge(ra, {
      scope = "${azurerm_storage_account.reusable_module[ra.storage_account_name].id}/blobServices/default/containers/${ra.container_name}"
      principal_id = ra.principal_type == "User" ? data.azuread_user.users[ra.principal_name].object_id : (
        ra.principal_type == "Group" ? data.azuread_group.groups[ra.principal_name].object_id : 
        data.azuread_service_principal.sps[ra.principal_name].object_id
      )
    })
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  depends_on           = [azurerm_storage_account.reusable_module, azurerm_storage_container.reusable_module]
}

resource "azurerm_storage_queue" "reusable_module" {
  for_each = {
    for key, queue in flatten([
      for sa_name, sa_config in local.storage_account_map : [
        for queue in sa_config.queues : {
          key                  = "${sa_name}-${queue.name}"
          storage_account_name = sa_name
          queue_name           = queue.name
          metadata             = try(queue.metadata, {})
        }
      ]
    ]) : queue.key => queue
  }

  name                 = each.value.queue_name
  storage_account_name = azurerm_storage_account.reusable_module[each.value.storage_account_name].name
  metadata             = each.value.metadata
}

resource "azapi_resource" "reusable_module_table" {
  for_each = {
    for key, table in flatten([
      for sa_name, sa_config in local.storage_account_map : [
        for table in sa_config.tables : {
          key                  = "${sa_name}-${table.name}"
          storage_account_name = sa_name
          table_name           = table.name
          properties           = try(table.properties, {})
        }
      ]
    ]) : table.key => table
  }

  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  name      = each.value.table_name
  parent_id = "${azurerm_storage_account.reusable_module[each.value.storage_account_name].id}/tableServices/default"
  body = {
    properties = each.value.properties
  }
}