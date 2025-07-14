output "storage_account_list" {
  description = "Flattened list of storage account objects from YAML files."
  value       = local.storage_account_list
}

output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}