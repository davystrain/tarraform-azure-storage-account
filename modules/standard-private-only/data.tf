data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_user" "users" {
  for_each            = local.user_names
  user_principal_name = each.key
}

data "azuread_group" "groups" {
  for_each     = local.group_names
  display_name = each.key
}

data "azuread_service_principal" "sps" {
  for_each     = local.sp_names
  display_name = each.key
}

data "azurerm_private_dns_zone" "privatelink_blob_azure_net" {
  provider            = azurerm.pe-dns-infra
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "platform-dns-private"
}

# Private DNS zones do not exist for these 2 data resource blocks yet
# data "azurerm_private_dns_zone" "privatelink_queue_azure_net" {
#   provider            = azurerm.pe-dns-infra
#   name                = "privatelink.queue.core.windows.net"
#   resource_group_name = "platform-dns-private"
# }

# data "azurerm_private_dns_zone" "privatelink_table_azure_net" {
#   provider            = azurerm.pe-dns-infra
#   name                = "privatelink.table.core.windows.net"
#   resource_group_name = "platform-dns-private"
# }

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.virtual_network_resource_group_name
}
