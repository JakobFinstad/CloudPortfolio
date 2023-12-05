# main.tf

provider "azurerm" {
  features = {}
}

resource "azurerm_resource_group" "rg" {
  name     = "cloud-shell-storage-westeurope"
  location = "westeurope"
}
