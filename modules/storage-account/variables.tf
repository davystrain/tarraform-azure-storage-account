variable "resource_group_name" {
  description = "The name of the resource group where the storage account is located."
  type        = string
}

# variable "storage_account_name" {
#   description = "The name of the storage account."
#   type        = string
# }

variable "location" {
  description = "The Azure region where the storage account is located."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the storage account."
  type        = map(string)
  default     = {}
}

variable "access_tier" {
  description = "The access tier for the storage account."
  type        = string
}

variable "account_kind" {
  description = "The kind of storage account."
  type        = string
  default     = "StorageV2"
}

variable "account_replication_type" {
  description = "The replication type for the storage account."
  type        = string
  default     = "LRS"
}

variable "account_tier" {
  description = "The performance tier for the storage account."
  type        = string
  default     = "Standard"
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public."
  type        = bool
  default     = true
}

variable "allowed_copy_scope" {
  description = "Allowed copy scope."
  type        = string
  default     = ""
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

variable "dns_endpoint_type" {
  description = "DNS endpoint type."
  type        = string
  default     = "Standard"
}

variable "edge_zone" {
  description = "Edge zone."
  type        = string
  default     = ""
}

variable "https_traffic_only_enabled" {
  description = "Enable HTTPS traffic only."
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption."
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace."
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Enable large file share."
  type        = bool
  default     = true
}

variable "local_user_enabled" {
  description = "Enable local user."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version."
  type        = string
  default     = "TLS1_2"
}

variable "name" {
  description = "The name of the storage account."
  type        = string
}

variable "nfsv3_enabled" {
  description = "Enable NFSv3."
  type        = bool
  default     = false
}

variable "primary_access_key" {
  description = "Primary access key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "primary_blob_connection_string" {
  description = "Primary blob connection string."
  type        = string
  sensitive   = true
  default     = ""
}

variable "primary_connection_string" {
  description = "Primary connection string."
  type        = string
  sensitive   = true
  default     = ""
}

variable "public_network_access_enabled" {
  description = "Enable public network access."
  type        = bool
  default     = true
}

variable "queue_encryption_key_type" {
  description = "Queue encryption key type."
  type        = string
  default     = "Service"
}

variable "secondary_access_key" {
  description = "Secondary access key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "secondary_blob_connection_string" {
  description = "Secondary blob connection string."
  type        = string
  sensitive   = true
  default     = ""
}

variable "secondary_connection_string" {
  description = "Secondary connection string."
  type        = string
  sensitive   = true
  default     = ""
}

variable "sftp_enabled" {
  description = "Enable SFTP."
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key."
  type        = bool
  default     = false
}

variable "table_encryption_key_type" {
  description = "Table encryption key type."
  type        = string
  default     = "Service"
}

variable "blob_properties" {
  description = "Blob properties block."
  type = object({
    change_feed_enabled           = bool
    change_feed_retention_in_days = number
    default_service_version       = string
    last_access_time_enabled      = bool
    versioning_enabled            = bool
    container_delete_retention_policy = object({
      days = number
    })
    delete_retention_policy = object({
      days                     = number
      permanent_delete_enabled = bool
    })
  })
}

variable "network_rules" {
  description = "Network rules block."
  type = object({
    bypass                     = list(string)
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
}

variable "routing" {
  description = "Routing block."
  type = object({
    choice                      = string
    publish_internet_endpoints  = bool
    publish_microsoft_endpoints = bool
  })
}

variable "share_properties" {
  description = "Share properties block."
  type = object({
    retention_policy = object({
      days = number
    })
  })
}

variable "queue_names" {
  type = list(object({
    name     = string
    metadata = optional(map(string))
  }))
  default = []
}

variable "tables" {
  description = "List of storage tables with optional ACLs."
  type = list(object({
    name = string
    acl = optional(list(object({
      id = string
      access_policy = optional(object({
        expiry      = string
        permissions = string
        start       = string
      }))
    })))
  }))
  default = []
}