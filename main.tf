# main.tf
terraform { 
    backend "azurerm" { 
        resource_group_name         = "cloud-shell-storage-westeurope" 
        storage_account_name        = "portfoliotfstate" 
        container_name              = "tfstate" 
        key                         = "Rqf4t1ZkeygKDjemQmUxF7Ocvk9ROV6pB1D5gmTkHbiOvpGuau4Z1VevfiPfCsRb9SL9s/vkdGy1+AStf7FY5g=="
        use_oidc                    = true
    } 
}

provider "azurerm" {
  features{}
  use_oidc = true
}

data "azurerm_resource_group" "cloud-shell-storage-westeurope_rg" {
  name = "cloud-shell-storage-westeurope"
}

resource "azurerm_resource_group" "CloudPortfolio_rg" {
  name     = "CloudPortfolio"
  location = "West Europe"
}

data "azurerm_storage_account" "portfoliotfstate" {
  name = "portfoliotfstate"
  resource_group_name = data.azurerm_resource_group.cloud-shell-storage-westeurope_rg.name
}


resource "azurerm_virtual_network" "CloudPortfolio_vnet" {
  name                = "CloudPortVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.CloudPortfolio_rg.location
  resource_group_name = azurerm_resource_group.CloudPortfolio_rg.name
}

resource "azurerm_subnet" "CloudPortfolio_subnet" {
  name                 = "CloudPortSubnet"
  resource_group_name  = azurerm_resource_group.CloudPortfolio_rg.name
  virtual_network_name = azurerm_virtual_network.CloudPortfolio_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
  name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "CloudPortfolio_nsg" {
  name                = "CloudPortNSG"
  location            = azurerm_resource_group.CloudPortfolio_rg.location
  resource_group_name = azurerm_resource_group.CloudPortfolio_rg.name
}

resource "azurerm_network_security_rule" "CloudPortfolio_nsg_rule" {
  name                        = "HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.CloudPortfolio_rg.name
  network_security_group_name = azurerm_network_security_group.CloudPortfolio_nsg.name

}

resource "azurerm_network_security_rule" "AllowOutbound" {
  name                        = "AllowOutbound"
  priority                    = 2000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = azurerm_resource_group.CloudPortfolio_rg.name
  network_security_group_name = azurerm_network_security_group.CloudPortfolio_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "CloudPortfolio_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.CloudPortfolio_subnet.id
  network_security_group_id = azurerm_network_security_group.CloudPortfolio_nsg.id
}


resource "azurerm_service_plan" "CloudPortfolio_asp" {
  name                = "CloudPortAppServicePlan"
  location            = azurerm_resource_group.CloudPortfolio_rg.location
  resource_group_name = azurerm_resource_group.CloudPortfolio_rg.name

  os_type   = "Linux"   
  sku_name  = "B1"      
}
resource "azurerm_app_service_virtual_network_swift_connection" "network_connection" {
  app_service_id = azurerm_app_service.CloudPortfolio_app.id
  subnet_id      = azurerm_subnet.CloudPortfolio_subnet.id
}

resource "azurerm_app_service" "CloudPortfolio_app"{
  name                = "CloudPortAppService"
  location            = azurerm_resource_group.CloudPortfolio_rg.location
  resource_group_name = azurerm_resource_group.CloudPortfolio_rg.name
  app_service_plan_id = azurerm_service_plan.CloudPortfolio_asp.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }
}