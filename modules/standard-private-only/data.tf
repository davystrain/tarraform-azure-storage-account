data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azuread_user" "users" {
  for_each = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "User"
  ])
  user_principal_name = each.key
}

data "azuread_group" "groups" {
  for_each = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "Group"
  ])
  display_name = each.key
}


data "azuread_service_principal" "sps" {
  for_each = toset([
    for ra in var.container_role_assignments : ra.principal_name
    if ra.principal_type == "ServicePrincipal"
  ])
  display_name = each.key
}

data "azurerm_private_dns_zone" "privatelink_blob_azure_net" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_private_dns_zone" "privatelink_queue_azure_net" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_private_dns_zone" "privatelink_table_azure_net" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.virtual_network_resource_group_name
}