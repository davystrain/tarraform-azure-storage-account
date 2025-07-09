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

variable "access_tier" {
  description = "The access tier for the storage account."
  type        = string
  default     = "Hot"
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
  default     = false
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
variable "tags" {
  description = "A map of tags to assign to the storage account."
  type        = map(string)
  default     = {}
}

variable "blob_properties" {
  description = "Blob properties block."
  type = object({
    change_feed_enabled           = bool
    change_feed_retention_in_days = number
    default_service_version       = string
    last_access_time_enabled      = bool
    versioning_enabled            = bool
    container_delete_retention_policy = optional(object({
      days = number
    }))
    delete_retention_policy = optional(object({
      days                     = number
      permanent_delete_enabled = bool
    }))
    restore_policy = optional(object({
      days = number
    }))
  })
  default = null
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

variable "containers" {
  description = "List of storage containers with optional access types and metadata."
  type = list(object({
    name                  = string
    container_access_type = optional(string, "private")
  }))
  default = []
}
variable "blobs" {
  description = "List of storage blobs with optional metadata and content type."
  type = list(object({
    name                   = string
    storage_account_name   = string
    storage_container_name = string
    type                   = string
    encryption_scope       = optional(string)
  }))
  default = []
}
variable "queues" {
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
  }))
  default = []
}