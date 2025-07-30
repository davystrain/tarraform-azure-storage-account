data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}
data "azuread_user" "users" {
  for_each            = local.user_principals # Uses the local we created
  user_principal_name = each.value
}

data "azuread_group" "groups" {
  for_each     = local.group_principals # Uses the local we created
  display_name = each.value
}

data "azuread_service_principal" "sps" {
  for_each     = local.sp_principals # Uses the local we created
  display_name = each.value
}

data "azurerm_private_dns_zone" "privatelink_blob_azure_net" {
  provider            = azurerm.pe-dns-infra
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "terraform"
}

data "azurerm_private_dns_zone" "privatelink_queue_azure_net" {
  provider            = azurerm.pe-dns-infra
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = "terraform"
}

data "azurerm_private_dns_zone" "privatelink_table_azure_net" {
  provider            = azurerm.pe-dns-infra
  name                = "privatelink.table.core.windows.net"
  resource_group_name = "terraform"
}

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.virtual_network_resource_group_name
}