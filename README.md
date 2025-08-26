# Azure Storage Account Terraform Module

This repository contains a reusable Terraform module for deploying and managing Azure Storage Accounts. In addition to accounts, the module supports the creation of storage containers, queues and tables, and exposes a wide range of configuration arguments to enable flexible and secure storage deployments in Azure. Note: Tables and Queues are not deployed as part of the standard-private-only module as no private DNS zones exist for these at this time.

## Resources

- [azurerm_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)  
- [azurerm_storage_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container)
- [azurerm_storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue)  
- [azurerm_storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table)
  

## Example: Calling the standard Storage Module

1. **Prepare your YAML files**
   
This module is data driven using a yaml data file. Place your Storage Account configuration files (with extensions .yaml or .yml) in a directory. Each file should contain one or multiple Storage Account configuration mappings. Below is an example of a yaml configuration file:

**Note:** A single storage account can contain multiple containers, queues and/or tables.
```yaml
standardexample1:
  resource_group_name: "examplergname"
  # Create containers
  containers:
    - name: "container1"
      # Create role assignments
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
  # Create queues
  queues:
    - name: "queue1"
  # Create tables
  tables:
    - name: "table1"
```
2. **Update the parent module main.tf file**

Ensure the `storage_use_azuread` argument is set to `true` in the main.tf file of the parent module call, as the AzureRM provider uses AzureAD to connect to the storage blob & queue APIs, rather than the shared key from the storage account as that is set to `shared_access_key_enabled = false`.
```hcl
provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = "6f90e55d-e95f-4043-87eb-a961825e7789"
  storage_use_azuread             = true
  features {}
}
``` 
3. **Invoke the Module**

Use the locals value in your Terraform configuration to convert the yaml files into Storage Account configurations. Here is an example of how to use it to target your yaml files:

```hcl
module "yaml-to-standard" {
  source           = "git::https://github.com/davystrain/terraform-azure-storage-account//modules//yaml-to-standard?ref=[git-tag]"
  yaml_config_path = "../../data/standard"
}
```
3. **Use the output to create new Storage Accounts**

The module will output a map of Storage Account configurations that can be used with the [terraform-azure-storage-account](https://github.com/davystrain/terraform-azure-storage-account) module. There are many options available and you may wish to override some of the defaults. Below is an example of how to use the output from the yaml-to-standard module to create Storage Accounts and additioanlly role assignments at the container scope:
```hcl
module "storage" {
  source   = "git::https://github.com/davystrain/terraform-azure-storage-account//modules//standard?ref=[git-tag]"
  for_each = module.yaml-to-standard.storage_account_map

  # Required
  name                     = each.key
  resource_group_name      = each.value.resource_group_name

  # optional
  containers                 = each.value.containers
  container_role_assignments = each.value.container_role_assignments
  queues                     = each.value.queues
  tables                     = each.value.tables
}
```

## Example: Calling the standard-private-only Module
1. **Prepare your YAML files**
   
This module is data driven using a yaml data file. Place your Storage Account configuration files (with extensions .yaml or .yml) in a directory. Each file should contain one or multiple Storage Account configuration mappings. Below is an example of a yaml configuration file:

**Note:** A single storage account can contain multiple containers, queues and/or tables.
```yaml
standardexample1:
  resource_group_name: "examplergname"
  # Create containers
  containers:
    - name: "container1"
      # Create role assignments
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
  # Create queues
  queues:
    - name: "queue1"
  # Create tables
  tables:
    - name: "table1"
    private_endpoint_subnet_name: "examplesubnet"
    virtual_network_name: "example-vnet-name"
    virtual_network_resource_group_name: "examplergname"
```
2. **Invoke the Module**

```hcl
module "yaml-to-standard-private-only" {
  source           = "git::https://github.com/davystrain/terraform-azure-storage-account//modules//yaml-standard-private-only?ref=[git-tag]"
  yaml_config_path = "../../data/standard-private-only"
}
```
3. **Use the output to create new Storage Accounts**

When deploying private only storage accounts the private endpoint subnet will need referenced by additional arguments as shown in the example below and the module will output a map of Storage Account configurations that can be used with the `terraform-azure-storage-account` module:
```hcl
module "storage" {
  source   = "git::https://github.com/davystrain/terraform-azure-storage-account//modules//standard-private-only?ref=[git-tag]"
  for_each = module.yaml-to-standard-private-only.storage_account_map

  providers = {
    azurerm              = azurerm
    azurerm.pe-dns-infra = azurerm.test-connectivity
  }

  # Required
  name                     = each.key
  resource_group_name      = each.value.resource_group_name

  # optional
  containers                 = each.value.containers
  container_role_assignments = each.value.container_role_assignments
  queues                     = each.value.queues
  tables                     = each.value.tables

  private_endpoint_subnet_name        = each.value.private_endpoint_subnet_name
  virtual_network_name                = each.value.virtual_network_name
  virtual_network_resource_group_name = each.value.virtual_network_resource_group_name
}

```
## Requirements - standard-private-only
Note: The `azurerm.test-connectivity` provider is required to manage the private DNS zone for the storage account private endpoints. Ensure that you have the necessary permissions and configurations in place for this provider.

```hcl
provider "azurerm" {
  alias               = "test-connectivity"
  subscription_id     = "e252dcaa-2add-4aac-a333-e035786c749b"
}
```
Service principals generated by the `github-repo-management` repo should have the necessary permissions to manage the private DNS zone for the Storage Account private endpoints.
## Example: Calling the Storage Module Using Hardcoded Values  
Change `source = ...//standard?ref=[git-tag]` to `source = ...//standard-private-only?ref=[git-tag]` accordingly.
```hcl
module "hardcoded_storage" {
  source = "git::https://github.com/davystrain/terraform-azure-storage-account//standard?ref=[git-tag]"

  name                             = "examplestorageaccountname"
  resource_group_name              = "examplergname"
  location                         = "australiaeast"

  containers = [
    {
      name                  = "examplescname"
      container_access_type = "private"
      role_assignments = {
        User = {
          "Storage Blob Data Reader" = [
            "example.com"
          ]
        }
        Group = {
          "Storage Blob Data Contributor" = [
            "examplegroupname"
          ]
        }
        ServicePrincipal = {
          "Storage Blob Data Owner" = [
            "examplespname1",
            "examplespname2"
          ]
        }
      }
    }
  ]

  queues = [
    {
      name = "examplequeuename"
    }
  ]

  tables = [
    {
      name = "exampletablename"
    }
  ]

  tags = {
    key = "value"
    key = "value"
  }
}
```
## Input Arguments

| Name                             | Required | Type        | Default      | Description                                                                                       |
|---------------------------------|----------|------------|-------------|---------------------------------------------------------------------------------------------------|
| **name**                         | Yes      | string     | n/a         | Name of the storage account. Must be unique, lowercase, and alphanumeric.                        |
| **resource_group_name**          | Yes      | string     | n/a         | Resource group in which to create the storage account.                                            |
| **location**                     | Yes      | string     | australiaeast         | Azure region where the storage account exists, for example, `australiaeast`.                                                   |
| **account_tier**                 | Yes      | string     | Standard    | Storage account tier. Options: `Standard`, `Premium`.                                            |
| **account_replication_type**     | Yes      | string     | LRS         | Replication type. Options: `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS`.                       |
| **account_kind**                 | No       | string     | StorageV2   | Defines the kind of account. Options: `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage`, `StorageV2`. |
| **cross_tenant_replication_enabled** | No   | bool       | false       | Prevent unauthorized data replication across tenants.                                           |
| **access_tier**                  | No       | string     | Hot         | Access tier for `BlobStorage`, `FileStorage`, `StorageV2`. Options: `Hot`, `Cool`, `Cold`, `Premium`. |
| **https_traffic_only_enabled**   | No       | bool       | true        | Forces HTTPS if enabled.                                                                         |
| **min_tls_version**              | No       | string     | TLS1_2      | Minimum supported TLS version. Options: `TLS1_0`, `TLS1_1`, `TLS1_2`.                             |
| **allow_nested_items_to_be_public** | No    | bool       | false       | Whether nested items can be publicly accessible.                                                 |
| **shared_access_key_enabled**    | No       | bool       | false       | Allow requests to be authorized using the account access key.                                    |
| **public_network_access_enabled** | No      | bool       | false       | Whether public network access is enabled. (`true` for `standard storage accounts` and `false` for `standard private storage accounts`)                                                      |
| **default_to_oauth_authentication** | No    | bool       | true        | Default to Azure AD authorization in the portal.                                                |
| **blob_properties**              | No       | object     | see *Note   | Blob properties to configures backup and recovery features for your Azure Storage.
| **network_rules**                | No       | object     | see *Note   | Network rules for the storage account.                                                          |
| **local_user_enabled**           | No       | bool       | false       | Enables local users. Defaults to `true` (can be insecure).                                      |
| **infrastructure_encryption_enabled** | No  | bool       | true        | Enable infrastructure encryption for the storage account.                                        |
| **tags**                         | No       | map(string)| {}          | Mapping of tags to assign to the resource.                                                      |
| **containers**                   | No       | list(object)| []         | List of blob containers to create                           |
| **queues**                       | No       | list(object)| []         | List of storage queue objects to create                        |
| **tables**                       | No       | list(object)| []         | List of storage table objects to create                        |


> **Note:** Some complex arguments (like `blob_properties`, `network_rules`, etc.) have their own nested required/optional fields. See the [Terraform documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)
