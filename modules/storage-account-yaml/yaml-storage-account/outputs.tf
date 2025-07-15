output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}

output "role_assignments_map" {
  description = "Map of all role assignments for storage accounts and sub-resources."
  value       = local.role_assignments_map
}