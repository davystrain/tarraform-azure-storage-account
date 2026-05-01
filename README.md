# Azure Storage Account Terraform Module

A reusable Terraform module collection for deploying and managing Azure Storage Accounts. The modules support creating storage containers, queues, and tables with fine-grained Azure RBAC assignments, and are available in two deployment flavours: **standard** (public network access allowed) and **standard-private-only** (network-isolated with private endpoints). A companion pair of **yaml-to-\*** data-transformation modules lets you drive deployments from simple YAML configuration files rather than duplicating HCL.

## Table of Contents

- [What This Module Provisions](#what-this-module-provisions)
- [Module Overview](#module-overview)
- [Requirements](#requirements)
- [Azure Authentication](#azure-authentication)
- [Usage Examples](#usage-examples)
  - [Pattern 1 – YAML-driven standard deployment](#pattern-1--yaml-driven-standard-deployment)
  - [Pattern 2 – YAML-driven private-only deployment](#pattern-2--yaml-driven-private-only-deployment)
  - [Pattern 3 – Hardcoded HCL deployment](#pattern-3--hardcoded-hcl-deployment)
- [YAML Configuration Reference](#yaml-configuration-reference)
- [Module Inputs](#module-inputs)
  - [standard](#standard-module-inputs)
  - [standard-private-only](#standard-private-only-module-inputs)
  - [yaml-to-standard and yaml-to-standard-private-only](#yaml-to-standard-and-yaml-to-standard-private-only-module-inputs)
- [Module Outputs](#module-outputs)
- [Resources Created](#resources-created)
- [Versioning](#versioning)

---

## What This Module Provisions

| Resource | standard | standard-private-only |
|---|---|---|
| `azurerm_storage_account` | ✓ | ✓ |
| `azurerm_storage_container` | ✓ | ✓ |
| Storage queues (`azapi_resource`) | ✓ | ✓ |
| Storage tables (`azapi_resource`) | ✓ | ✓ |
| Container-level RBAC (`azurerm_role_assignment`) | ✓ | ✓ |
| Blob private endpoint | ✗ | ✓ |
| Table private endpoint | ✗ | ✓ |

**Security defaults applied to every storage account:**

- Shared access key authentication disabled (`shared_access_key_enabled = false`)
- HTTPS-only traffic enforced
- Minimum TLS version: TLS 1.2
- Infrastructure-level encryption enabled
- Cross-tenant replication disabled
- Public blob access disabled

---

## Module Overview

```
modules/
├── standard/                      # Public-accessible storage account + resources
├── standard-private-only/         # Network-isolated storage account + private endpoints
├── yaml-to-standard/              # Parses YAML → map consumed by standard/
└── yaml-to-standard-private-only/ # Parses YAML → map consumed by standard-private-only/
```

Use the **yaml-to-\*** modules when you want to manage many storage accounts through data files.  
Use **standard** or **standard-private-only** directly when you prefer to pass configuration as Terraform variables.

---

## Requirements

| Tool | Minimum version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.3` (for `optional()` in object types) |
| [hashicorp/azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | `>= 3.0` |
| [hashicorp/azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest) | `>= 2.0` |
| [Azure/azapi](https://registry.terraform.io/providers/Azure/azapi/latest) | `>= 1.0` |

---

## Azure Authentication

All modules resolve principal names to Azure AD object IDs and manage role assignments, so the identity running Terraform needs the following permissions:

- **Storage Account Contributor** (or higher) on the target resource group, to create/modify storage accounts.
- **Role Based Access Control Administrator** on the storage account/container scope, to create role assignments.
- **Azure AD read permissions** – at minimum `User.Read.All`, `Group.Read.All`, and `ServicePrincipal.Read.All` on the Microsoft Graph API, so principal names can be resolved to object IDs.
- For `standard-private-only` – **Network Contributor** on the VNet resource group to create private endpoints, and **Private DNS Zone Contributor** on the subscription hosting the private DNS zones.

Because shared access key authentication is disabled, the AzureRM provider **must** be configured with `storage_use_azuread = true` so the provider authenticates to the Storage blob and queue APIs via Azure AD rather than a storage key:

```hcl
provider "azurerm" {
  subscription_id                  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  resource_provider_registrations  = "none"
  storage_use_azuread              = true
  features {}
}
```

For `standard-private-only`, a second provider alias is required to manage the private DNS zones (which typically live in a central connectivity subscription):

```hcl
# Primary provider – target workload subscription
provider "azurerm" {
  subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  storage_use_azuread = true
  features {}
}

# Provider alias – connectivity/DNS-infra subscription
provider "azurerm" {
  alias           = "pe-dns-infra"
  subscription_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  features {}
}
```

Service principals created by the `github-repo-management` repo should already have the necessary permissions to manage private DNS zones for storage account private endpoints.

---

## Usage Examples

### Pattern 1 – YAML-driven standard deployment

**Step 1 – Create YAML configuration files**

Place one or more `.yaml` / `.yml` files in a directory (e.g. `data/standard/`). Each file maps storage account names to their configuration. A single account can contain multiple containers, queues, and/or tables.

```yaml
# data/standard/my-storage-accounts.yaml

mystorageaccount:
  resource_group_name: "my-resource-group"
  location: "australiaeast"               # optional – defaults to australiaeast
  account_replication_type: "LRS"         # optional – defaults to LRS

  containers:
    - name: "application-data"
      role_assignments:
        User:
          Storage Blob Data Reader:
            - user@example.com
        Group:
          Storage Blob Data Contributor:
            - my-aad-group
        ServicePrincipal:
          Storage Blob Data Owner:
            - my-github-actions-sp

  queues:
    - name: "work-queue"

  tables:
    - name: "audit-log"
```

**Step 2 – Parse the YAML**

```hcl
module "yaml_to_standard" {
  source           = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/yaml-to-standard?ref=<git-tag>"
  yaml_config_path = "../../data/standard"
}
```

**Step 3 – Create the storage accounts**

```hcl
module "storage" {
  source   = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/standard?ref=<git-tag>"
  for_each = module.yaml_to_standard.storage_account_map

  name                       = each.key
  resource_group_name        = each.value.resource_group_name

  containers                 = each.value.containers
  container_role_assignments = each.value.container_role_assignments
  queues                     = each.value.queues
  tables                     = each.value.tables
}
```

---

### Pattern 2 – YAML-driven private-only deployment

**Step 1 – Create YAML configuration files**

```yaml
# data/standard-private-only/my-private-accounts.yaml

myprivatestorageaccount:
  resource_group_name: "my-resource-group"
  location: "australiaeast"

  containers:
    - name: "secure-data"
      role_assignments:
        ServicePrincipal:
          Storage Blob Data Reader:
            - my-app-service-principal

  private_endpoint_subnet_name:        "pe-subnet"
  virtual_network_name:                "my-vnet"
  virtual_network_resource_group_name: "my-network-resource-group"
```

> **Note:** Tables and queues are omitted from `standard-private-only` deployments because private DNS zones for those sub-services are not yet available.

**Step 2 – Parse the YAML**

```hcl
module "yaml_to_private" {
  source           = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/yaml-to-standard-private-only?ref=<git-tag>"
  yaml_config_path = "../../data/standard-private-only"
}
```

**Step 3 – Create the private storage accounts**

```hcl
module "storage_private" {
  source   = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/standard-private-only?ref=<git-tag>"
  for_each = module.yaml_to_private.storage_account_map

  providers = {
    azurerm              = azurerm
    azurerm.pe-dns-infra = azurerm.pe-dns-infra
  }

  name                = each.key
  resource_group_name = each.value.resource_group_name

  containers                 = each.value.containers
  container_role_assignments = each.value.container_role_assignments

  private_endpoint_subnet_name        = each.value.private_endpoint_subnet_name
  virtual_network_name                = each.value.virtual_network_name
  virtual_network_resource_group_name = each.value.virtual_network_resource_group_name
}
```

---

### Pattern 3 – Hardcoded HCL deployment

Use this approach when you prefer to manage a single storage account inline without YAML. Swap `//modules/standard` for `//modules/standard-private-only` (adding the required private endpoint variables) for a network-isolated deployment.

```hcl
module "storage" {
  source = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/standard?ref=<git-tag>"

  name                = "examplestorageaccount"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"

  containers = [
    {
      name = "application-data"
    },
    {
      name = "archive"
    }
  ]

  container_role_assignments = [
    {
      container_name       = "application-data"
      principal_type       = "ServicePrincipal"
      role_definition_name = "Storage Blob Data Contributor"
      principal_name       = "my-app-service-principal"
    }
  ]

  queues = [
    {
      name = "work-queue"
    }
  ]

  tables = [
    {
      name = "audit-log"
    }
  ]

  tags = {
    environment = "production"
    team        = "platform"
  }
}
```

---

## YAML Configuration Reference

Both YAML modules accept the same top-level keys. Fields not listed default to the module's Terraform variable defaults.

```yaml
<storage-account-name>:
  # --- Required ---
  resource_group_name: string

  # --- Optional account settings ---
  location: string                      # default: "australiaeast"
  account_tier: string                  # default: "Standard"  (Standard | Premium)
  account_replication_type: string      # default: "LRS"       (LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS)
  account_kind: string                  # default: "StorageV2"
  access_tier: string                   # default: "Hot"       (Hot | Cool | Cold | Premium)
  public_network_access_enabled: bool   # default: true (standard) / false (private-only)
  shared_access_key_enabled: bool       # default: false
  default_to_oauth_authentication: bool # default: true
  infrastructure_encryption_enabled: bool # default: true

  # --- Optional containers ---
  containers:
    - name: string
      role_assignments:
        User:
          "<role-name>":
            - "<user-upn>"
        Group:
          "<role-name>":
            - "<group-display-name>"
        ServicePrincipal:
          "<role-name>":
            - "<sp-display-name>"

  # --- Optional queues ---
  queues:
    - name: string

  # --- Optional tables ---
  tables:
    - name: string

  # --- Required for standard-private-only only ---
  private_endpoint_subnet_name: string
  virtual_network_name: string
  virtual_network_resource_group_name: string
```

---

## Module Inputs

### `standard` module inputs

| Name | Required | Type | Default | Description |
|---|---|---|---|---|
| `name` | **Yes** | `string` | — | Storage account name. Must be globally unique, 3–24 characters, lowercase alphanumeric. |
| `resource_group_name` | **Yes** | `string` | — | Resource group in which to create the storage account. |
| `location` | No | `string` | `"australiaeast"` | Azure region for the storage account. |
| `account_tier` | No | `string` | `"Standard"` | Performance tier. Options: `Standard`, `Premium`. |
| `account_replication_type` | No | `string` | `"LRS"` | Replication type. Options: `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS`. |
| `account_kind` | No | `string` | `"StorageV2"` | Account kind. Options: `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage`, `StorageV2`. |
| `access_tier` | No | `string` | `"Cool"` | Blob access tier. Options: `Hot`, `Cool`, `Cold`, `Premium`. |
| `cross_tenant_replication_enabled` | No | `bool` | `false` | Allow cross-tenant replication. |
| `https_traffic_only_enabled` | No | `bool` | `true` | Enforce HTTPS-only traffic. |
| `min_tls_version` | No | `string` | `"TLS1_2"` | Minimum TLS version. Options: `TLS1_0`, `TLS1_1`, `TLS1_2`. |
| `allow_nested_items_to_be_public` | No | `bool` | `false` | Allow public access to nested blob items. |
| `shared_access_key_enabled` | No | `bool` | `false` | Enable shared-key authentication (storage key). |
| `public_network_access_enabled` | No | `bool` | `true` | Enable public network access. Set to `false` for network-isolated workloads. |
| `default_to_oauth_authentication` | No | `bool` | `true` | Default to Azure AD (OAuth) in the Azure portal. |
| `local_user_enabled` | No | `bool` | `false` | Enable local user authentication (SFTP/NFS). |
| `infrastructure_encryption_enabled` | No | `bool` | `true` | Enable a second layer of infrastructure encryption. |
| `tags` | No | `map(string)` | `{}` | Tags to assign to the storage account resource. |
| `blob_properties` | No | `object(…)` | See below | Blob service settings: versioning, change feed, retention policies. |
| `network_rules` | No | `object(…)` | See below | Network ACL settings: bypass, default action, IP rules, VNet rules. |
| `containers` | No | `list(object({ name }))` | `[]` | Blob containers to create. |
| `container_role_assignments` | No | `list(object(…))` | `[]` | RBAC assignments scoped to individual containers. |
| `queues` | No | `list(object({ name }))` | `[]` | Storage queues to create. |
| `tables` | No | `list(object({ name, properties? }))` | `[]` | Storage tables to create. |

**`blob_properties` default:**

```hcl
{
  change_feed_enabled           = true
  change_feed_retention_in_days = 30
  default_service_version       = "2023-01-03"
  last_access_time_enabled      = false
  versioning_enabled            = true
  container_delete_retention_policy = { days = 7 }
  delete_retention_policy           = { days = 7, permanent_delete_enabled = false }
  restore_policy                    = { days = 6 }
}
```

**`network_rules` default:**

```hcl
{
  bypass                     = ["AzureServices"]
  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = []
}
```

---

### `standard-private-only` module inputs

Inherits all inputs from the `standard` module above, with the following differences and additions:

| Name | Required | Type | Default | Description |
|---|---|---|---|---|
| `access_tier` | No | `string` | `"Hot"` | Default changes to `Hot` for private accounts. |
| `public_network_access_enabled` | No | `bool` | `false` | Public access is **disabled** by default. |
| `private_endpoint_subnet_name` | **Yes** | `string` | — | Subnet name in which to place the private endpoints. |
| `virtual_network_name` | **Yes** | `string` | — | VNet that contains the private endpoint subnet. |
| `virtual_network_resource_group_name` | **Yes** | `string` | — | Resource group of the VNet. |

The `containers` variable in this module also accepts an optional `container_access_type` field (default: `"private"`).

The `queues` variable accepts an optional `properties.metadata` map. The `tables` variable accepts an optional `properties.signedIdentifiers` list for scoped access policies.

---

### `yaml-to-standard` and `yaml-to-standard-private-only` module inputs

| Name | Required | Type | Description |
|---|---|---|---|
| `yaml_config_path` | **Yes** | `string` | Path to the directory containing `.yaml` / `.yml` storage account configuration files. |

---

## Module Outputs

### `standard` and `standard-private-only`

| Name | Description |
|---|---|
| `storage_account_id` | The fully-qualified Azure Resource ID of the storage account. |
| `storage_account_name` | The name of the storage account. |

### `yaml-to-standard` and `yaml-to-standard-private-only`

| Name | Description |
|---|---|
| `storage_account_map` | Map of storage account configurations keyed by account name. Pass directly to `for_each` when calling a `standard` or `standard-private-only` module. |

---

## Resources Created

| Terraform resource | Provider | Notes |
|---|---|---|
| `azurerm_storage_account` | hashicorp/azurerm | Core storage account |
| `azurerm_storage_container` | hashicorp/azurerm | One per entry in `containers` |
| `azurerm_role_assignment` | hashicorp/azurerm | One per entry in `container_role_assignments` |
| `azapi_resource` (queue) | Azure/azapi | One per entry in `queues`; uses API version `2022-09-01` |
| `azapi_resource` (table) | Azure/azapi | One per entry in `tables`; uses API version `2022-09-01` |
| `azurerm_private_endpoint` (blob) | hashicorp/azurerm | `standard-private-only` only; linked to `privatelink.blob.core.windows.net` |
| `azurerm_private_endpoint` (table) | hashicorp/azurerm | `standard-private-only` only; linked to `privatelink.table.core.windows.net` |

Principal name resolution (users, groups, service principals) is performed automatically via the `azuread` provider data sources.

---

## Versioning

This repository uses semantic versioning via git tags. Tags are created through the [tagging-version workflow](.github/workflows/tagging-version.yml), which supports `major`, `minor`, and `patch` bumps and is triggered manually via `workflow_dispatch`.

Always pin module sources to a specific tag to ensure reproducible deployments:

```hcl
source = "git::https://github.com/<org-name>/tarraform-azure-storage-account//modules/standard?ref=v1.2.3"
```
