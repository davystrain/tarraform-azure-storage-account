output "storage_account_map" {
  description = "Map of storage accounts with their configurations"
  value       = local.storage_account_map
}

output "storage_containers" {
  description = "Map of container keys to their IDs"
  value       = { for k, v in azurerm_storage_container.containers : k => v.id }
}

output "storage_queues" {
  description = "Map of queue keys to their IDs"
  value       = { for k, v in azurerm_storage_queue.queues : k => v.id }
}

output "storage_tables" {
  description = "Map of table keys to their IDs"
  value       = { for k, v in azapi_resource.tables : k => v.id }
}

output "container_role_assignments" {
  description = "Map of container role assignments"
  value       = local.container_role_assignments
}