terraform {
  required_version = ">= 1.16.6, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

provider "azurerm" {
  features {}
  environment                     = "usgovernment"
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Network", "Microsoft.Insights"]
}

module "vnet" {
  source = "../.."

  vnet_name             = var.vnet_name
  resource_group_name   = var.resource_group_name
  address_space         = var.address_space
  diag_log_analytics_id = var.diag_log_analytics_id

  subnets = {
    "app-sn-1" = {
      address_prefix           = cidrsubnet(var.address_space[0], 8, 1)
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    "pe-sn-1" = {
      address_prefix = cidrsubnet(var.address_space[0], 8, 2)
    }
    "psql-sn-1" = {
      address_prefix     = cidrsubnet(var.address_space[0], 8, 3)
      subnet_delegations = ["Microsoft.DBforPostgreSQL/flexibleServers"]
    }
  }

  core_private_dns_zone_ids = var.core_private_dns_zone_ids
  tags                      = var.tags
}
