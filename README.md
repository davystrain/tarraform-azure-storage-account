# Azure Storage Account Terraform Module

This repository contains a reusable Terraform module for deploying and managing Azure Storage Accounts. The module supports the creation of storage queues and tables, and exposes a wide range of configuration arguments to enable flexible and secure storage deployments in Azure.

## Resources

- [azurerm_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)  
- [azurerm_storage_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container)
- [azurerm_storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob)  
- [azurerm_storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue)  
- [azurerm_storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table)

## Example: Calling the Standard Storage Module

1. **Prepare your YAML files**
   
This module is data driven using a yaml data file. Place your Storage Account configuration files (with extensions .yaml or .yml) in a directory. Each file should contain one or multiple Storage Account configuration mappings. Below is an example of a YAML configuration file:

**Note:** A single storage account can contain multiple containers, each of which can store multiple blobs. Additionally, the same storage account can also host multiple queues and tables.
```yaml
storage_accounts:
  storageaccountone: # Storage account name
    resource_group_name: "terraform"
    location: "australiaeast"
    access_tier: "Hot"
    account_kind: "StorageV2"
    account_replication_type: "LRS"
    account_tier: "Standard"
    allow_nested_items_to_be_public: true
    local_user_enabled: false
    cross_tenant_replication_enabled: false
    default_to_oauth_authentication: true
    https_traffic_only_enabled: true
    min_tls_version: "TLS1_2"
    public_network_access_enabled: true 
    shared_access_key_enabled: false
    blob_properties:
      change_feed_enabled: true 
      change_feed_retention_in_days: 1 
      default_service_version: "2023-01-03"
      last_access_time_enabled: false
      versioning_enabled: true 
      container_delete_retention_policy:
        days: 7
      delete_retention_policy: 
        days: 7
        permanent_delete_enabled: false
      restore_policy:
        days: 6 
    network_rules:
      bypass: ["None"]
      default_action: "Allow" 
      ip_rules: [] 
      virtual_network_subnet_ids: []
    tags: {
      environment: "dev",
      owner: "teamA"
      }
    # Create containers
    containers:
      - name: "container1"
        container_access_type: "private"
        role_assignments:
          User:
            Storage Account Contributor:
              - example.com
          Group:
            Storage Account Contributor:
              - AAD DC Administrators
          ServicePrincipal:
            Role Based Access Control Administrator:
              - github-actions-infra-apply
              - github-actions-infra-plan
      - name: "container2"
        container_access_type: "private"
        role_assignments:
          User:
            Storage Account Contributor:
              - example.com
          Group:
            Storage Account Contributor:
              - AAD DC Administrators
              - dynamic_retail
          ServicePrincipal:
            Role Based Access Control Administrator:
              - github-actions-infra-apply
              - github-actions-infra-plan
    # Create blobs
    blobs:
      - name: "blob3"
        storage_container_name: "container1"
        type: "Block"
    # Create queues
    queues:
      - name: "queue1"
    # Create tables
    tables:
      - name: "table1"      
```
2. **Invoke the Module**

Use the yaml-to-vm module in your Terraform configuration to convert the YAML files into Storage Account configurations. Here is an example of how to use the module:

```hcl
module "yaml-to-storage-account" {
  source           = "git::https://github.com/racwa/terraform-azure-storage-account//modules//standard//yaml-to-storage-account?ref=[git-tag]"
  yaml_config_path = "../../data/storage-accounts"
}
```
3. **Use the yaml-to-storage-account output to create new Storage Accounts**

The module will output a map of Storage Account configurations that can be used with the [terraform-azure-storage-account](https://github.com/racwa/terraform-azure-storage-account) module. There are many options available and you may wish to override some of the defaults. Below is an example of how to use the output from the yaml-to-storage-account module to create Storage Accounts:
```hcl
module "storage" {
  source   = "git::https://github.com/racwa/terraform-azure-storage-account//modules//standard?ref=[git-tag]"
  for_each = local.storage_account_map

  # Required variables
  name                     = each.key
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location
  access_tier              = each.value.access_tier
  account_replication_type = each.value.account_replication_type
  account_tier             = each.value.account_tier

  # Optional variables with defaults from your variable definitions
  account_kind                     = try(each.value.account_kind, "StorageV2")
  allow_nested_items_to_be_public  = try(each.value.allow_nested_items_to_be_public, false)
  cross_tenant_replication_enabled = try(each.value.cross_tenant_replication_enabled, false)
  default_to_oauth_authentication  = try(each.value.default_to_oauth_authentication, true)
  https_traffic_only_enabled       = try(each.value.https_traffic_only_enabled, true)
  min_tls_version                  = try(each.value.min_tls_version, "TLS1_2")
  public_network_access_enabled    = try(each.value.public_network_access_enabled, false)
  shared_access_key_enabled        = try(each.value.shared_access_key_enabled, false)
  local_user_enabled               = try(each.value.local_user_enabled, false)

  # Complex types
  containers = try(each.value.containers, [])
  queues     = try(each.value.queues, [])
  tables     = try(each.value.tables, [])
  tags       = try(each.value.tags, {})
}
```

## Example: Calling the standard-storage-private-only Module
```hcl

<enter terraform config here>

```

## Example: Calling the Module Using Hardcoded Values
```hcl

module "storage" {
  source = "git::https://github.com/racwa/terraform-azure-storage-account//modules//standard?ref=[git-tag]"

  # Required arguments
  name                     = "example-storage-account"
  resource_group_name      = "example-rg"
  location                 = "australiaeast"
  access_tier              = "Hot"
  account_replication_type = "LRS"
  account_tier             = "Standard"

  # Optional arguments
  account_kind                     = "StorageV2"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
  default_to_oauth_authentication  = true
  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"
  public_network_access_enabled    = true
  shared_access_key_enabled        = false
  local_user_enabled               = false

  blob_properties = null
  network_rules   = null

  containers = [
    {
      name                  = "container1"
      container_access_type = "private"
    },
    {
      name                  = "container2"
      container_access_type = "private"
    }
  ]
  container_role_assignments = [
    {
      storage_account_name = "myhardcodedstorage"
      resource_group_name  = "terraform"
      container_name       = "container1"
      principal_type       = "User"
      role_definition_name = "Storage Blob Data Contributor"
      principal_name       = "example.com"
    },
    {
      storage_account_name = "myhardcodedstorage"
      resource_group_name  = "terraform"
      container_name       = "container1"
      principal_type       = "Group"
      role_definition_name = "Storage Blob Data Contributor"
      principal_name       = "example group name"
    },
    {
      storage_account_name = "myhardcodedstorage"
      resource_group_name  = "terraform"
      container_name       = "container1"
      principal_type       = "ServicePrincipal"
      role_definition_name = "Storage Blob Data Contributor"
      principal_name       = "example service principal name"
    }
  ]
  blobs  = []
  queues = []
  tables = []

  tags = {
    environment = "dev"
    owner       = "teamA"
  }
}

```
## Input Arguments

| Name                                | Optional/Required | Type           | Default Setting | Short Description                                                                                   |
|-------------------------------------|-------------------|----------------|------------------|-----------------------------------------------------------------------------------------------------|
| name                                | REQUIRED          | string         | n/a              | Specifies the name of the storage account. Must be unique and lowercase alphanumeric.               |
| resource_group_name | REQUIRED          | string         | n/a              | The name of the resource group in which to create the storage account.                              |
| location                            | REQUIRED          | string         | australiaeast    | Azure region where the resource exists.                                                             |
| account_tier                        | REQUIRED          | string         | "Standard"       | Tier for the storage account. Options: Standard, Premium.                                           |
| account_replication_type            | REQUIRED          | string         | "LRS"            | Replication type. Options: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS.                                      |
| account_kind                        | Optional          | string         | "StorageV2"      | Defines the Kind of account. Options: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2 |
| cross_tenant_replication_enabled    | Optional          | bool           | false            | Should cross Tenant replication be enabled?                                                         |
| access_tier                         | Optional          | string         | "Hot"            | Access tier for BlobStorage, FileStorage, StorageV2. Options: Hot, Cool, Cold, Premium.             |
| https_traffic_only_enabled          | Optional          | bool           | true             | Forces HTTPS if enabled.                                                                            |
| min_tls_version                     | Optional          | string         | "TLS1_2"         | Minimum supported TLS version. Options: TLS1_0, TLS1_1, TLS1_2.                                     |
| allow_nested_items_to_be_public     | Optional          | bool           | false            | Allow nested items to be public.                                                                    |
| shared_access_key_enabled           | Optional          | bool           | false            | Allow requests to be authorized with the account access key.                                        |
| public_network_access_enabled       | Optional          | bool           | false            | Whether public network access is enabled.                                                           |
| default_to_oauth_authentication     | Optional          | bool           | true             | Default to Azure AD authorization in the portal.                                                    |
| custom_domain                       | Optional          | object         | null             | Custom domain block.                                                                                |
| identity                            | Optional          | object         | null             | Identity block for managed identities.                                                              |
| blob_properties                     | Optional          | object         | null             | Blob properties block.                                                                              |
| network_rules                       | Optional          | object         | Deny             | Network rules block.                                                                                |
| local_user_enabled                  | Optional          | bool           | false            | Is Local User Enabled?                                                                              |
| dns_endpoint_type                   | Optional          | string         | "Standard"       | DNS endpoint type. Options: Standard (250 storage accounts per subscription per region), AzureDnsZone (Create additional 5000 Azure Storage accounts within your Subscription).                                                 |
| tags                                | Optional          | map(string)    | {}               | Mapping of tags to assign to the resource.                                                          |
| containers                          | Optional          | list(object)   | []               | List of blob containers to create (e.g., [{ name = "container1" }]).                               |
| blobs                               | Optional          | list(object)   | []               | List of blobs to upload (e.g., [{ name = "file.txt", source = "local/path/file.txt" }]).            |
| queues                              | Optional          | list(object)   | []               | List of storage queue objects to create (e.g., [{ name = "queue1" }]).                              |
| tables                              | Optional          | list(object)   | []               | List of storage table objects to create (e.g., [{ name = "table1" }]).                              |

> **Note:** Some complex arguments (like `blob_properties`, `network_rules`, etc.) have their own nested required/optional fields. See the [Terraform documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)


