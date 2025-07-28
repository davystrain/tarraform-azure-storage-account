output "storage_accounts" {
  description = "Map of storage account names to their configurations"
  value       = { for k, v in azurerm_storage_account.accounts : k => v }
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

output "role_assignments" {
  description = "Map of role assignment keys to their IDs"
  value       = { for k, v in azurerm_role_assignment.container_roles : k => v.id }
}