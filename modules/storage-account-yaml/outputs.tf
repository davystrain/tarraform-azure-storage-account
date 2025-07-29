output "storage_account_ids" {
  description = "Map of storage account names to their IDs."
  value       = { for name, sa in azurerm_storage_account.sa : name => sa.id }
}