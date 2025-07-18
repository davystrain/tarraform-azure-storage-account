output "storage_account_map" {
  description = "Map of storage account name to storage account object."
  value       = local.storage_account_map
}
output "container_role_assignments_map" {
  description = "value of container role assignments map."
  value = local.container_role_assignments_map
}
