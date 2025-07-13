data "azurerm_resource_group" "private_endpoint" {
  name = var.resource_group_name
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