output "storage_account_map" {
  description = "Map of storage accounts with their configurations"
  value       = local.storage_account_map
}

output "container_role_assignments" {
  description = "List of role assignments for containers"
  value       = local.container_role_assignments
}