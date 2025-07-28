output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}

output "storage_container_ids" {
  description = "Map of storage container names to their IDs."
  value       = { for c in azurerm_storage_container.reusable_module : c.name => c.id }
}
