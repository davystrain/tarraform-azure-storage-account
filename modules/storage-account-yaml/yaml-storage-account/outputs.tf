output "storage_account_list" {
  description = "Flattened list of storage account objects from YAML files."
  value       = local.storage_account_list
}

output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}

# Group Assignment Outputs
output "group_assignments" {
  description = "Map of group role assignments"
  value       = local.group_assignments
}

output "group_names" {
  description = "Set of unique group names for data source lookups"
  value       = local.group_names
}

# User Assignment Outputs
output "user_assignments" {
  description = "Map of user role assignments"
  value       = local.user_assignments
}