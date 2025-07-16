output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}

output "container_role_assignments" {
  value = local.container_role_assignments
  description = "Flattened list of container role assignments extracted from YAML"
}

output "container_role_assignments_map" {
  value = local.container_role_assignments_map
}
