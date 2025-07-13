terraform {
  required_version = ">= 1.12.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm, azurerm.pe-dns-infra]
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.5.0"
    }
  }
}

