output "storage_container_ids" {
  description = "Map of storage container names to their IDs."
  value       = { for c in azurerm_storage_container.sc : c.name => c.id }
}
