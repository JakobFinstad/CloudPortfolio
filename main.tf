# main.tf

variable tenant_id {}

variable client_id {}

terraform { 
    backend "azurerm" { 
        resource_group_name         = "CloudPortfolio" 
        storage_account_name        = "portfoliotfstate" 
        container_name              = "tfstate" 
        key                         = "CloudPortfolio.tfstate"
        use_oidc                    = true
    } 
}

provider "azurerm" {
  features{}
  client_id = var.client_id
  tenant_id = var.tenant_id
}


resource "azurerm_resource_group" "CloudPortfolio_rg" {
  name     = "CloudPortfolio"
  location = "West Europe"
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