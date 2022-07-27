terraform {
  required_version = "1.1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "prd-mgmt-va-core-rg"
    storage_account_name = "prdmgmtvampsatfstate"
    container_name       = "va<app-abbreviation>tfstatecontainer"
    environment          = "usgovernment"
    key                  = "va-mgmt-network.tfstate"
  }
}
