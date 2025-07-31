output "storage_account_id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.sa.id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.sa.name
}