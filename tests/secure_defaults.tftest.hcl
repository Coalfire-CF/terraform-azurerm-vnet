# Offline checks for the secure subnet defaults, the input guards and tag
# merging. The provider is mocked, so no Azure credentials are needed.
#
# Run order matters. State carries across runs in one file, and after an
# apply the mock subnet ids are random strings that the association
# resources cannot parse. Keep every plan run above the single apply run,
# which must stay last.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name     = "test-rg"
      location = "usgovvirginia"
    }
  }

  mock_data "azurerm_monitor_diagnostic_categories" {
    defaults = {
      log_category_groups = ["allLogs"]
      log_category_types  = ["VMProtectionAlerts"]
      metrics             = ["AllMetrics"]
    }
  }
}

variables {
  vnet_name             = "test-vnet"
  resource_group_name   = "test-rg"
  address_space         = ["10.10.0.0/16"]
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
  tags                  = { Function = "Networking" }
  regional_tags         = { Region = "usgovvirginia" }
  nsg_ids               = {}
  route_tables_ids      = {}
  subnets = {
    app = {
      address_prefix           = "10.10.1.0/24"
      subnet_service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    bare = {
      address_prefix = "10.10.2.0/24"
    }
  }
}

run "subnet_defaults_are_secure" {
  command = plan

  assert {
    condition     = azurerm_subnet.subnet["bare"].private_endpoint_network_policies == "Enabled"
    error_message = "private_endpoint_network_policies must default to Enabled."
  }

  assert {
    condition     = azurerm_subnet.subnet["bare"].private_link_service_network_policies_enabled == true
    error_message = "private_link_service_network_policies_enabled must default to true."
  }

  assert {
    condition     = azurerm_subnet.subnet["bare"].default_outbound_access_enabled == false
    error_message = "default_outbound_access_enabled must default to false."
  }
}

run "subnet_overrides_apply" {
  command = plan

  variables {
    subnets = {
      app = {
        address_prefix           = "10.10.1.0/24"
        subnet_service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      }
      bare = {
        address_prefix                                = "10.10.2.0/24"
        private_endpoint_network_policies             = "Disabled"
        private_link_service_network_policies_enabled = false
        default_outbound_access_enabled               = true
      }
    }
  }

  assert {
    condition     = azurerm_subnet.subnet["bare"].private_endpoint_network_policies == "Disabled"
    error_message = "A private_endpoint_network_policies override must reach the subnet."
  }

  assert {
    condition     = azurerm_subnet.subnet["bare"].private_link_service_network_policies_enabled == false
    error_message = "A private_link_service_network_policies_enabled override must reach the subnet."
  }

  assert {
    condition     = azurerm_subnet.subnet["bare"].default_outbound_access_enabled == true
    error_message = "A default_outbound_access_enabled override must reach the subnet."
  }

  assert {
    condition     = azurerm_subnet.subnet["app"].private_endpoint_network_policies == "Enabled" && azurerm_subnet.subnet["app"].private_link_service_network_policies_enabled == true && azurerm_subnet.subnet["app"].default_outbound_access_enabled == false
    error_message = "An override on one subnet must not change the defaults on another."
  }
}

run "invalid_private_endpoint_policy_rejected" {
  command = plan

  variables {
    subnets = {
      bare = {
        address_prefix                    = "10.10.2.0/24"
        private_endpoint_network_policies = "Bogus"
      }
    }
  }

  expect_failures = [var.subnets]
}

run "nsg_key_must_match_subnet" {
  command = plan

  variables {
    nsg_ids = { missing = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg" }
  }

  expect_failures = [var.nsg_ids]
}

run "route_table_key_must_match_subnet" {
  command = plan

  variables {
    route_tables_ids = { missing = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt" }
  }

  expect_failures = [var.route_tables_ids]
}

run "nsg_valid_key_accepted" {
  command = plan

  variables {
    nsg_ids = { app = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg" }
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.vnet) == 1
    error_message = "An nsg_ids key that names a subnet must create one association."
  }
}

run "route_table_valid_key_accepted" {
  command = plan

  variables {
    route_tables_ids = { app = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-rt" }
  }

  assert {
    condition     = length(azurerm_subnet_route_table_association.vnet) == 1
    error_message = "A route_tables_ids key that names a subnet must create one association."
  }
}

run "tags_are_merged" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.vnet.tags == tomap({ Function = "Networking", Region = "usgovvirginia" })
    error_message = "The VNet must carry tags merged with regional_tags."
  }
}

run "dns_link_skipped_when_disabled" {
  command = plan

  variables {
    create_private_dns_zone = false
    core_private_dns_zone_ids = {
      "privatelink.blob.core.usgovcloudapi.net" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net"
    }
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.default) == 0
    error_message = "No DNS zone link may be created when create_private_dns_zone is false."
  }
}

run "subnet_address_output" {
  command = plan

  assert {
    condition     = output.subnet_addresses["app"] == "10.10.1.0/24"
    error_message = "subnet_addresses must map each subnet name to its address prefix."
  }
}

# Smoke run: the apply completes with diagnostics v3.0.0 under the mock. It
# does not prove the diagnostics module is wired; removing module.diag still
# passes. The override gives the VNet a well-formed id because the provider
# parses resource_id in the diagnostics module's categories data source.
run "diagnostics_module_applies" {
  command = apply

  override_resource {
    target = azurerm_virtual_network.vnet
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    }
  }

  assert {
    condition     = azurerm_virtual_network.vnet.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    error_message = "The apply must complete with the overridden VNet id."
  }
}
