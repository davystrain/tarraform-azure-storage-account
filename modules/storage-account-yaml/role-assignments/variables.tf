variable "container_role_assignments" {
  description = "List of role assignments for storage containers"
  type = list(object({
    storage_account_name = string
    resource_group_name  = string
    container_name       = string
    principal_type       = string
    role_definition_name = string
    principal_name       = string
  }))
  default = []
}
