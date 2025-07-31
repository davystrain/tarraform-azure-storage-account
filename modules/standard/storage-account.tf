resource "azurerm_storage_account" "sa" {
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
}

resource "azurerm_storage_container" "sc" {
  for_each           = { for c in var.containers : c.name => c }
  name               = each.value.name
  storage_account_id = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "container_roles" {
  for_each = local.container_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  depends_on           = [azurerm_storage_account.sa, azurerm_storage_container.sc]
}

resource "azurerm_storage_queue" "sq" {
  for_each             = { for q in var.queues : q.name => q }
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.sa.name
  metadata             = try(each.value.metadata, {})
}

# UPDATED: Tables using for_each
resource "azapi_resource" "reusable_module_table" {
  for_each  = { for t in var.tables : t.name => t }
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  name      = each.value.name
  parent_id = "${azurerm_storage_account.sa.id}/tableServices/default"
  body = {
    properties = try(each.value.properties, {})
  }
}




