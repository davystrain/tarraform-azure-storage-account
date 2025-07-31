resource "azurerm_storage_account" "reusable_module" {
  name                             = var.name
  resource_group_name              = data.azurerm_resource_group.private_endpoint.name
  location                         = data.azurerm_resource_group.private_endpoint.location
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
  tags                             = var.tags

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
  for_each           = { for c in var.containers : c.name => c }
  name               = each.value.name
  storage_account_id = azurerm_storage_account.reusable_module.id
}

resource "azurerm_role_assignment" "container_roles" {
  for_each = local.container_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  depends_on           = [azurerm_storage_account.reusable_module, azurerm_storage_container.reusable_module]
}

resource "azurerm_storage_queue" "reusable_module" {
  for_each             = { for q in var.queues : q.name => q }
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.reusable_module.name
  metadata             = try(each.value.metadata, {})
}

# UPDATED: Tables using for_each
resource "azapi_resource" "reusable_module_table" {
  for_each  = { for t in var.tables : t.name => t }
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  name      = each.value.name
  parent_id = "${azurerm_storage_account.reusable_module.id}/tableServices/default"
  body = {
    properties = try(each.value.properties, {})
  }
}

resource "azurerm_private_endpoint" "blob" {
  count = length(var.containers) > 0 ? 1 : 0

  name                          = "${azurerm_storage_account.reusable_module.name}-pe1"
  location                      = data.azurerm_resource_group.private_endpoint.location
  resource_group_name           = data.azurerm_resource_group.private_endpoint.name
  subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
  custom_network_interface_name = "pe1-${var.name}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_blob_azure_net.id]
  }

  private_service_connection {
    name                           = "${azurerm_storage_account.reusable_module.name}-psc"
    private_connection_resource_id = azurerm_storage_account.reusable_module.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  depends_on = [azurerm_storage_account.reusable_module]

  tags = var.tags
}
resource "azurerm_private_endpoint" "queue" {
  count = length(var.queues) > 0 ? 1 : 0

  name                          = "${azurerm_storage_account.reusable_module.name}-pe2"
  location                      = data.azurerm_resource_group.private_endpoint.location
  resource_group_name           = data.azurerm_resource_group.private_endpoint.name
  subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
  custom_network_interface_name = "pe2-${var.name}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_queue_azure_net.id]
  }

  private_service_connection {
    name                           = "${azurerm_storage_account.reusable_module.name}-psc"
    private_connection_resource_id = azurerm_storage_account.reusable_module.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
  depends_on = [azurerm_storage_account.reusable_module]

  tags = var.tags
}
resource "azurerm_private_endpoint" "table" {
  count = length(var.tables) > 0 ? 1 : 0

  name                          = "${azurerm_storage_account.reusable_module.name}-pe3"
  location                      = data.azurerm_resource_group.private_endpoint.location
  resource_group_name           = data.azurerm_resource_group.private_endpoint.name
  subnet_id                     = data.azurerm_subnet.private_endpoint_subnet.id
  custom_network_interface_name = "pe3-${var.name}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.privatelink_table_azure_net.id]
  }

  private_service_connection {
    name                           = "${azurerm_storage_account.reusable_module.name}-psc"
    private_connection_resource_id = azurerm_storage_account.reusable_module.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
  depends_on = [azurerm_storage_account.reusable_module]

  tags = var.tags
}