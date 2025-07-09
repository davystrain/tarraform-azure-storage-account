terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# resource "azurerm_resource_group" "rg" {
#   name     = var.name
#   location = var.location
# }

# output "resource_group" {
#   value = azurerm_resource_group.rg
# }

resource "azurerm_storage_account" "reusable_module" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
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
  blob_properties {
    change_feed_enabled           = var.blob_properties.change_feed_enabled
    change_feed_retention_in_days = var.blob_properties.change_feed_retention_in_days
    default_service_version       = var.blob_properties.default_service_version
    last_access_time_enabled      = var.blob_properties.last_access_time_enabled
    versioning_enabled            = var.blob_properties.versioning_enabled

    container_delete_retention_policy {
      days = var.blob_properties.container_delete_retention_policy.days
    }

    delete_retention_policy {
      days                     = var.blob_properties.delete_retention_policy.days
      permanent_delete_enabled = var.blob_properties.delete_retention_policy.permanent_delete_enabled
    }

    restore_policy {
      days = var.blob_properties.restore_policy.days
    }
  }

  network_rules {
    bypass                     = var.network_rules.bypass
    default_action             = var.network_rules.default_action
    ip_rules                   = var.network_rules.ip_rules
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
  }

  routing {
    choice                      = var.routing.choice
    publish_internet_endpoints  = var.routing.publish_internet_endpoints
    publish_microsoft_endpoints = var.routing.publish_microsoft_endpoints
  }
}

resource "azurerm_storage_container" "reusable_module" {
  count                 = length(var.containers)
  name                  = var.containers[count.index].name
  storage_account_id    = azurerm_storage_account.reusable_module.id
  container_access_type = try(var.containers[count.index].container_access_type, "private")
}

resource "azurerm_storage_blob" "reusable_module" {
  count                  = length(var.blobs)
  name                   = var.blobs[count.index].name
  storage_account_name   = azurerm_storage_account.reusable_module.name
  storage_container_name = var.blobs[count.index].storage_container_name
  type                   = var.blobs[count.index].type
}

resource "azurerm_storage_queue" "reusable_module" {
  count                = length(var.queues)
  name                 = var.queues[count.index].name
  storage_account_name = azurerm_storage_account.reusable_module.name
}

resource "azurerm_storage_table" "reusable_module" {
  count                = length(var.tables)
  name                 = var.tables[count.index].name
  storage_account_name = azurerm_storage_account.reusable_module.name
}