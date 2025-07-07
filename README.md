# Azure Storage Account Terraform Module

This repository contains a reusable Terraform module for deploying and managing Azure Storage Accounts. The module supports the creation of storage queues and tables, and exposes a wide range of configuration arguments to enable flexible and secure storage deployments in Azure.

## Resources

- [azurerm_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)  
- [azurerm_storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob)  
- [azurerm_storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue)  
- [azurerm_storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table)

## Example: Calling the module

This module is data driven using a yaml data file

```hcl
locals {
  storage_vars = yamldecode(file("${path.module}/data/storage_vars.yaml"))
}

module "storage" {
  for_each = local.storage_vars.storage_accounts
  source   = "git::https://github.com/racwa/terraform-azure-storage-account?ref=[git-tag]"

## Required fields
  name                     = each.key
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location
  access_tier              = each.value.access_tier
  account_replication_type = each.value.account_replication_type
  account_tier             = each.value.account_tier

## Optional fields
  account_kind             = try(each.value["account_kind"], null)

}

```
## Input Arguments

| Name                                | Optional/Required | Type           | Default Setting | Short Description                                                                                   |
|-------------------------------------|-------------------|----------------|------------------|-----------------------------------------------------------------------------------------------------|
| name                                | REQUIRED          | string         | n/a              | Specifies the name of the storage account. Must be unique and lowercase alphanumeric.               |
| storage_account_resource_group_name | REQUIRED          | string         | n/a              | The name of the resource group in which to create the storage account.                              |
| location                            | REQUIRED          | string         | n/a              | Azure region where the resource exists.                                                             |
| account_tier                        | REQUIRED          | string         | "Standard"       | Tier for the storage account. Options: Standard, Premium.                                           |
| account_replication_type           | REQUIRED          | string         | "LRS"            | Replication type. Options: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS.  
| account_kind                        | Optional          | string         | "StorageV2"      | Defines the Kind of account. Options: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2 |                                    |
| cross_tenant_replication_enabled    | Optional          | bool           | false            | Should cross Tenant replication be enabled?                                                         |
| access_tier                         | Optional          | string         | "Hot"            | Access tier for BlobStorage, FileStorage, StorageV2. Options: Hot, Cool, Cold, Premium.             |
| edge_zone                           | Optional          | string         | ""               | Edge Zone within the Azure Region.                                                                  |
| https_traffic_only_enabled          | Optional          | bool           | true             | Forces HTTPS if enabled.                                                                            |
| min_tls_version                     | Optional          | string         | "TLS1_2"         | Minimum supported TLS version. Options: TLS1_0, TLS1_1, TLS1_2.                                     |
| allow_nested_items_to_be_public     | Optional          | bool           | true             | Allow nested items to be public.                                                                    |
| shared_access_key_enabled           | Optional          | bool           | true             | Allow requests to be authorized with the account access key.                                        |
| public_network_access_enabled       | Optional          | bool           | true             | Whether public network access is enabled.                                                           |
| default_to_oauth_authentication     | Optional          | bool           | false            | Default to Azure AD authorization in the portal.                                                    |
| is_hns_enabled                      | Optional          | bool           | false            | Is Hierarchical Namespace enabled (Data Lake Storage Gen2)?                                         |
| nfsv3_enabled                       | Optional          | bool           | false            | Is NFSv3 protocol enabled?                                                                          |
| custom_domain                       | Optional          | object         | null             | Custom domain block.                                                                                |
| customer_managed_key                | Optional          | object         | null             | Customer managed key block.                                                                         |
| identity                            | Optional          | object         | null             | Identity block for managed identities.                                                              |
| blob_properties                     | Optional          | object         | null             | Blob properties block.                                                                              |
| queue_properties                    | Optional          | object         | null             | Queue properties block.                                                                             |
| static_website                      | Optional          | object         | null             | Static website block.                                                                               |
| network_rules                       | Optional          | object         | null             | Network rules block.                                                                                |
| large_file_share_enabled            | Optional          | bool           | false            | Are Large File Shares enabled?                                                                      |
| local_user_enabled                  | Optional          | bool           | true             | Is Local User Enabled?                                                                              |
| azure_files_authentication          | Optional          | object         | null             | Azure Files authentication block.                                                                   |
| routing                             | Optional          | object         | null             | Routing block.                                                                                      |
| queue_encryption_key_type           | Optional          | string         | "Service"        | Encryption type of the queue service. Options: Service, Account.                                    |
| table_encryption_key_type           | Optional          | string         | "Service"        | Encryption type of the table service. Options: Service, Account.                                    |
| infrastructure_encryption_enabled   | Optional          | bool           | false            | Is infrastructure encryption enabled?                                                               |
| immutability_policy                 | Optional          | object         | null             | Immutability policy block.                                                                          |
| sas_policy                          | Optional          | object         | null             | SAS policy block.                                                                                   |
| allowed_copy_scope                  | Optional          | string         | ""               | Restrict copy to/from Storage Accounts within an AAD tenant or Private Links.                       |
| sftp_enabled                        | Optional          | bool           | false            | Enable SFTP for the storage account.                                                                |
| dns_endpoint_type                   | Optional          | string         | "Standard"       | DNS endpoint type. Options: Standard, AzureDnsZone.                                                 |
| tags                                | Optional          | map(string)    | {}               | Mapping of tags to assign to the resource.                                                          |
| queue_names                         | Optional          | list(object)   | []               | List of storage queue objects to create (e.g., [{ name = "queue1" }]).                              |
| tables                              | Optional          | list(object)   | []               | List of storage table objects to create (e.g., [{ name = "table1" }]).                              |

> **Note:** Some complex arguments (like `blob_properties`, `network_rules`, etc.) have their own nested required/optional fields. See the [Terraform documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)


