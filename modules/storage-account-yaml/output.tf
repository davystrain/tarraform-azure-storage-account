output "storage_account_id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.reusable_module.id
}

output "storage_container_ids" {
  description = "Map of storage container names to their IDs."
  value       = { for c in azurerm_storage_container.reusable_module : c.name => c.id }
}

output "resource_group_location" {
  value = data.azurerm_resource_group.rg.location
}
