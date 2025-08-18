# Azure Storage Account Terraform Module

This repository contains a reusable Terraform module for deploying and managing Azure Storage Accounts. In addition to accounts, the module supports the creation of storage containers, queues and tables, and exposes a wide range of configuration arguments to enable flexible and secure storage deployments in Azure.

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
storage_accounts:
  storageaccountone: # Storage account name
    resource_group_name: "examplergname"
    location: "australiaeast"
    network_rules:
      bypass: ["AzureServices"]
      default_action: "Deny"
      ip_rules: []
      virtual_network_subnet_ids: []
    tags: # Resource group tags will be included by default
      key: "value"
      key: "value"
    # Create containers
    containers:
      - name: "container1"
        container_access_type: "private"
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
    # Create queues
    queues:
      - name: "queue1"
    # Create tables
    tables:
      - name: "table1"
```
2. **Invoke the Module**

Use the locals value in your Terraform configuration to convert the yaml files into Storage Account configurations. Here is an example of how to use it to target your yaml files:

```hcl
module "yaml-to-standard" {
  source           = "git::https://github.com/davystrain/module-resource-group.git//modules//yaml-to-standard?ref=v1.0.0"
  yaml_config_path = "../../data/standard"
}
```
3. **Use the output to create new Storage Accounts**

The module will output a map of Storage Account configurations that can be used with the [terraform-azure-storage-account](git::https://github.com/davystrain/module-resource-group) module. There are many options available and you may wish to override some of the defaults. Below is an example of how to use the output from the yaml-to-standard module to create Storage Accounts and additioanlly role assignments at the container scope:
```hcl
module "storage" {
  source   = "git::https://github.com/davystrain/module-resource-group.git//modules//standard?ref=v1.0.0"
  for_each = module.yaml-to-standard.storage_account_map

  # Required
  name                     = each.key
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location

  containers = try(each.value.containers, [])
  queues     = try(each.value.queues, [])
  tables     = try(each.value.tables, [])
  tags       = try(each.value.tags, {})
}
```

## Example: Calling the standard-private-only Module
1. **Prepare your YAML files**
   
This module is data driven using a yaml data file. Place your Storage Account configuration files (with extensions .yaml or .yml) in a directory. Each file should contain one or multiple Storage Account configuration mappings. Below is an example of a yaml configuration file:

**Note:** A single storage account can contain multiple containers, queues and/or tables.
```yaml
storage_accounts:
  storageaccountone: # Storage account name
    resource_group_name: "examplergname"
    location: "australiaeast"
    network_rules:
      bypass: ["AzureServices"]
      default_action: "Deny"
      ip_rules: []
      virtual_network_subnet_ids: []
    tags: # Resource group tags will be included by default
      key: "value"
      key: "value"
    # Create containers
    containers:
      - name: "container1"
        container_access_type: "private"
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
  source           = "git::https://github.com/davystrain/module-resource-group.git//modules//yaml-to-standard-private-only?ref=v1.0.0"
  yaml_config_path = "../../data/standard-private-only"
}
```
3. **Use the output to create new Storage Accounts**

When deploying private only storage accounts the private endpoint subnet will need referenced by additional arguments as shown in the example below and the module will output a map of Storage Account configurations that can be used with the `terraform-azure-storage-account` module:
```hcl
module "storage" {
  source   = "git::https://github.com/davystrain/module-resource-group.git//modules//standard-private-only?ref=v1.0.0"
  for_each = module.yaml-to-standard-private-only.storage_account_map

  providers = {
    azurerm              = azurerm
    azurerm.pe-dns-infra = azurerm.test-connectivity
  }

  # Required
  name                     = each.key
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location

  containers = try(each.value.containers, [])
  queues     = try(each.value.queues, [])
  tables     = try(each.value.tables, [])
  tags       = try(each.value.tags, {})

  private_endpoint_subnet_name        = try(each.value.private_endpoint_subnet_name, null)
  virtual_network_name                = try(each.value.virtual_network_name, null)
  virtual_network_resource_group_name = try(each.value.virtual_network_resource_group_name, null)
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
  source = "git::https://github.com/davystrain/module-resource-group.git//modules//standard?ref=v1.0.0"

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

| Name                                | Optional/Required | Type           | Default Setting | Short Description                                                                                   |
|-------------------------------------|-------------------|----------------|------------------|-----------------------------------------------------------------------------------------------------|
| name                                | REQUIRED          | string         | n/a              | Specifies the name of the storage account. Must be unique and lowercase alphanumeric.               |
| resource_group_name | REQUIRED          | string         | n/a              | The name of the resource group in which to create the storage account.                              |
| location                            | REQUIRED          | string         | australiaeast    | Azure region where the resource exists.                                                             |
| account_tier                        | REQUIRED          | string         | "Standard"       | Tier for the storage account. Options: Standard, Premium.                                           |
| account_replication_type            | REQUIRED          | string         | "LRS"            | Replication type. Options: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS.                                      |
| account_kind                        | Optional          | string         | "StorageV2"      | Defines the Kind of account. Options: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2 |
| cross_tenant_replication_enabled    | Optional          | bool           | false            | Set to false tp prevent unauthorised data leakage across tenants                                                        |
| access_tier                         | Optional          | string         | "Hot"            | Access tier for BlobStorage, FileStorage, StorageV2. Options: Hot, Cool, Cold, Premium.             |
| https_traffic_only_enabled          | Optional          | bool           | true             | Forces HTTPS if enabled.                                                                            |
| min_tls_version                     | Optional          | string         | "TLS1_2"         | Minimum supported TLS version. Options: TLS1_0, TLS1_1, TLS1_2.                                     |
| allow_nested_items_to_be_public     | Optional          | bool           | false            | Allow nested items to be public.                                                                    |
| shared_access_key_enabled           | Optional          | bool           | false            | Allow requests to be authorized with the account access key.                                        |
| public_network_access_enabled       | Optional          | bool           | false            | Whether public network access is enabled.                                                           |
| default_to_oauth_authentication     | Optional          | bool           | true             | Default to Azure AD authorization in the portal.                                                    |                                                                          |
| network_rules                       | Optional          | object         | Deny             | Network rules block.                                                                                |
| local_user_enabled                  | Optional          | bool           | false            | Defaults to true which can be insecure.                                                                              |                                                |
| tags                                | Optional          | map(string)    | {}               | Mapping of tags to assign to the resource.                                                          |
| containers                          | Optional          | list(object)   | []               | List of blob containers to create (e.g., [{ name = "container1" }]).                               |
| queues                              | Optional          | list(object)   | []               | List of storage queue objects to create (e.g., [{ name = "queue1" }]).                              |
| tables                              | Optional          | list(object)   | []               | List of storage table objects to create (e.g., [{ name = "table1" }]).                              |

> **Note:** Some complex arguments (like `blob_properties`, `network_rules`, etc.) have their own nested required/optional fields. See the [Terraform documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)


