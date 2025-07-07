output "storage_queues" {
  description = "The storage queues created."
  value       = azurerm_storage_queue.reusable_module[*].name
}

output "storage_tables" {
  description = "The storage tables created."
  value       = azurerm_storage_table.reusable_module[*].name
}

output "storage_account_id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.reusable_module.id 
}