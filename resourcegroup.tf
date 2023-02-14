
#create resource group
resource "azurerm_resource_group" "rg-host-pool" {
  name     = var.rg-host-pool
  location = var.location
  }

#Storage account
resource "azurerm_storage_account" "host_pool_sc" {
  name                     = var.host_pool_sc
  resource_group_name      = var.rg-host-pool
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  depends_on = [azurerm_resource_group.rg-host-pool]
}