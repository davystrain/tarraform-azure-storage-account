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
}

variable "access_tier" {
  description = "The access tier for the storage account."
  type        = string
}

variable "account_replication_type" {
  description = "The replication type for the storage account."
  type        = string
}

variable "account_tier" {
  description = "The performance tier for the storage account."
  type        = string
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

variable "network_rules" {
  description = "Network rules block."
  type = object({
    bypass                     = list(string)
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    bypass                     = []
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

variable "containers" {
  description = "List of storage containers"
  type = list(object({
    name = string
  }))
  default = []
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

