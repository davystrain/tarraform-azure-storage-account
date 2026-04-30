variable "name" {
  description = "The name of the storage account."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the storage account is located."
  type        = string
}

variable "location" {
  description = "The Azure region where the storage account is located."
  type        = string
  default     = "australiaeast"
}

variable "account_tier" {
  description = "The performance tier for the storage account."
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The replication type for the storage account."
  type        = string
  default     = "LRS"
}

variable "access_tier" {
  description = "The access tier for the storage account."
  type        = string
  default     = "Hot"
}

variable "account_kind" {
  description = "The kind of storage account."
  type        = string
  default     = "StorageV2"
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public."
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Enable cross-tenant replication."
  type        = bool
  default     = false
}

variable "default_to_oauth_authentication" {
  description = "Default to OAuth authentication."
  type        = bool
  default     = true
}

variable "https_traffic_only_enabled" {
  description = "Enable HTTPS traffic only."
  type        = bool
  default     = true
}
variable "min_tls_version" {
  description = "Minimum TLS version."
  type        = string
  default     = "TLS1_2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access."
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key."
  type        = bool
  default     = false
}

variable "local_user_enabled" {
  description = "Enable local user authentication."
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the storage account."
  type        = map(string)
  default     = {}
}

variable "static_website" {
  description = "If static_website is set to true, the service will automatically create a azurerm_storage_container named $web."
  type        = bool
  default     = false
}

variable "static_website_index_document" {
  description = "The name of the index document for the static website."
  type        = string
  default     = null
}

variable "blob_properties" {
  description = "Blob properties block. Set to null to disable."
  type = object({
    change_feed_enabled           = optional(bool, true)
    change_feed_retention_in_days = optional(number, 30)
    default_service_version       = optional(string, "2023-01-03")
    last_access_time_enabled      = optional(bool, false)
    versioning_enabled            = optional(bool, true)
    container_delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), { days = 7 })
    delete_retention_policy = optional(object({
      days                     = optional(number, 7)
      permanent_delete_enabled = optional(bool, false)
      }),
      { days = 7, permanent_delete_enabled = false }
    )
    restore_policy = optional(object({
      days = optional(number)
    }), { days = 6 })
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])
  })
  default = {
    change_feed_enabled           = true
    change_feed_retention_in_days = 30
    default_service_version       = "2023-01-03"
    last_access_time_enabled      = false
    versioning_enabled            = true
    container_delete_retention_policy = {
      days = 7
    }
    delete_retention_policy = {
      days                     = 7
      permanent_delete_enabled = false
    }
    restore_policy = {
      days = 6
    }
    cors_rules = []
  }
}

variable "network_rules" {
  description = "Network rules block."
  type = object({
    bypass                     = list(string)
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
  })
  default = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    private_link_access        = []
  }
}

variable "containers" {
  description = "List of storage containers, with optional per-container lifecycle rules that are merged into a single azurerm_storage_management_policy on the storage account."
  type = list(object({
    name = string
    lifecycle_rules = optional(list(object({
      name    = string
      enabled = optional(bool, true)
      filters = optional(object({
        blob_types   = optional(list(string), ["blockBlob"])
        prefix_match = optional(list(string), [])
      }), { blob_types = ["blockBlob"], prefix_match = [] })
      actions = object({
        base_blob = optional(object({
          delete_after_days_since_modification_greater_than              = optional(number)
          delete_after_days_since_last_access_time_greater_than          = optional(number)
          delete_after_days_since_creation_greater_than                  = optional(number)
          tier_to_cool_after_days_since_modification_greater_than        = optional(number)
          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_cool_after_days_since_creation_greater_than            = optional(number)
          tier_to_cold_after_days_since_modification_greater_than        = optional(number)
          tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
          tier_to_archive_after_days_since_modification_greater_than     = optional(number)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_archive_after_days_since_creation_greater_than         = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        }))
        snapshot = optional(object({
          delete_after_days_since_creation_greater_than                  = optional(number)
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        }))
        version = optional(object({
          delete_after_days_since_creation                               = optional(number)
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        }))
      })
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for container in var.containers : alltrue([
        for rule in try(container.lifecycle_rules, []) :
        try(rule.actions.base_blob != null || rule.actions.snapshot != null || rule.actions.version != null, false)
      ])
    ])
    error_message = "Each lifecycle rule must define at least one of: base_blob, snapshot, or version in the actions block."
  }
}

variable "container_role_assignments" {
  description = "List of role assignments for containers"
  type = list(object({
    container_name       = string
    principal_type       = string
    role_definition_name = string
    principal_name       = string
  }))
  default = []
}

variable "queues" {
  type = list(object({
    name = string
  }))
  default = []
}

variable "tables" {
  description = "List of storage tables"
  type = list(object({
    name       = string
    properties = optional(map(any), {})
  }))
  default = []
}

variable "resource_role_assignments" {
  description = "RBAC role assignments for the Storage Account resource itself"
  type = object({
    Group            = optional(map(list(string)))
    ServicePrincipal = optional(map(list(string)))
    User             = optional(map(list(string)))
  })
  default = {}
}
