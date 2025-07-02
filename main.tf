terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
}

output "resource_group" {
  value = azurerm_resource_group.rg
}
