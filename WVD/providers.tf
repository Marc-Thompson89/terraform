# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
        version = "3.41.0"
      }
    azuread = {source = "hashicorp/azuread"
    }
  }
}
provider "azurerm" {
  features {}
}
