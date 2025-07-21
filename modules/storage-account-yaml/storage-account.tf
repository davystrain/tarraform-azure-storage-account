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
}

resource "azurerm_storage_container" "reusable_module" {
  for_each           = { for c in var.containers : c.name => c }
  name               = each.value.name
  storage_account_id = azurerm_storage_account.reusable_module.id
}



