# Storage accounts
resource "azurerm_storage_account" "accounts" {
  for_each = local.storage_account_map

  name                             = each.key
  resource_group_name              = data.azurerm_resource_group.rg[each.value.resource_group_name].name
  location                         = data.azurerm_resource_group.rg[each.value.resource_group_name].location
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

# Storage containers
resource "azurerm_storage_container" "containers" {
  for_each = merge([
    for sa_name, sa_config in local.storage_account_map : {
      for container in try(sa_config.containers, []) :
      "${sa_name}-${container.name}" => {
        storage_account_name  = sa_name
        container_name        = container.name
        container_access_type = try(container.container_access_type, "private")
      }
    }
  ]...)

  name                  = each.value.container_name
  storage_account_id    = azurerm_storage_account.accounts[each.value.storage_account_name].id
  container_access_type = each.value.container_access_type
}

# Storage queues
resource "azurerm_storage_queue" "queues" {
  for_each = merge([
    for sa_name, sa_config in local.storage_account_map : {
      for queue in try(sa_config.queues, []) :
      "${sa_name}-${queue.name}" => {
        storage_account_name = sa_name
        queue_name          = queue.name
        metadata           = try(queue.metadata, {})
      }
    }
  ]...)

  name                 = each.value.queue_name
  storage_account_name = azurerm_storage_account.accounts[each.value.storage_account_name].name
  metadata            = each.value.metadata
}

# Storage tables
resource "azapi_resource" "tables" {
  for_each = merge([
    for sa_name, sa_config in local.storage_account_map : {
      for table in try(sa_config.tables, []) :
      "${sa_name}-${table.name}" => {
        storage_account_name = sa_name
        table_name          = table.name
        properties         = try(table.properties, {})
      }
    }
  ]...)

  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  name      = each.value.table_name
  parent_id = "${azurerm_storage_account.accounts[each.value.storage_account_name].id}/tableServices/default"
  body = {
    properties = each.value.properties
  }
}

# Role assignments
resource "azurerm_role_assignment" "container_roles" {
  for_each = local.container_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  depends_on           = [azurerm_storage_account.accounts, azurerm_storage_container.containers]
}