# Offline checks for the azurerm 5.x schema changes. The provider is mocked, so
# no Azure credentials are needed: run `terraform init -backend=false` then
# `terraform test`.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name     = "test-rg"
      location = "usgovvirginia"
    }
  }
}

variables {
  vnet_name             = "test-vnet"
  resource_group_name   = "test-rg"
  address_space         = ["10.10.0.0/16"]
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
  tags                  = {}
  subnets = {
    app = {
      address_prefix           = "10.10.1.0/24"
      subnet_service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    bare = {
      address_prefix = "10.10.2.0/24"
    }
  }
  core_private_dns_zone_ids = {
    "privatelink.blob.core.usgovcloudapi.net" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net"
  }
}

run "service_endpoints_render_as_blocks_in_caller_order" {
  command = plan

  assert {
    condition     = [for se in azurerm_subnet.subnet["app"].service_endpoint : se.service] == ["Microsoft.Storage", "Microsoft.KeyVault"]
    error_message = "subnet_service_endpoints must become one service_endpoint block per service, in caller order."
  }

  assert {
    condition     = length(azurerm_subnet.subnet["bare"].service_endpoint) == 0
    error_message = "A subnet without subnet_service_endpoints must have no service_endpoint blocks."
  }
}

run "dns_zone_link_uses_zone_id" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.default["privatelink.blob.core.usgovcloudapi.net"].private_dns_zone_id == var.core_private_dns_zone_ids["privatelink.blob.core.usgovcloudapi.net"]
    error_message = "The DNS zone link must take private_dns_zone_id from core_private_dns_zone_ids."
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.default) == 1
    error_message = "Expected exactly one DNS zone link for one zone id."
  }
}
