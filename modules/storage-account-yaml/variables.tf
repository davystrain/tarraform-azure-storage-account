variable "yaml_config_path" {
  description = "Path to the YAML configuration files"
  type        = string
  default     = null
}

variable "storage_accounts" {
  description = "Map of storage account configurations"
  type = map(object({
    resource_group_name      = string
    location                 = string
    access_tier              = string
    account_replication_type = string
    account_tier             = string
    account_kind                     = optional(string, "StorageV2")
    allow_nested_items_to_be_public  = optional(bool, false)
    cross_tenant_replication_enabled = optional(bool, false)
    default_to_oauth_authentication  = optional(bool, true)
    https_traffic_only_enabled       = optional(bool, true)
    min_tls_version                  = optional(string, "TLS1_2")
    public_network_access_enabled    = optional(bool, false)
    shared_access_key_enabled        = optional(bool, false)
    local_user_enabled               = optional(bool, false)
    containers = optional(list(object({
      name                  = string
      container_access_type = optional(string, "private")
      role_assignments     = optional(map(map(list(string))), {})
    })), [])
    queues = optional(list(object({
      name     = string
      metadata = optional(map(string), {})
    })), [])
    tables = optional(list(object({
      name       = string
      properties = optional(map(any), {})
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}
