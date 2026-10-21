# Offline checks for the optional VNet flow log: off by default, on with
# traffic analytics, overrides, and the input guards. The provider is mocked,
# so no Azure credentials are needed.

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

run "flow_log_off_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_network_watcher_flow_log.vnet) == 0
    error_message = "No flow log must be planned when flow_log is not set."
  }

  assert {
    condition     = output.flow_log_id == null
    error_message = "flow_log_id must be null when flow_log is not set."
  }
}

run "flow_log_on_with_traffic_analytics" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  override_resource {
    target          = azurerm_virtual_network.vnet
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    }
  }

  override_resource {
    target          = azurerm_network_watcher_flow_log.vnet
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_usgovvirginia/flowLogs/test-vnet-flowlog"
    }
  }

  assert {
    condition     = length(azurerm_network_watcher_flow_log.vnet) == 1
    error_message = "Exactly one flow log must be planned when flow_log is set."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].target_resource_id == azurerm_virtual_network.vnet.id
    error_message = "The flow log must target the VNet."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].name == "test-vnet-flowlog"
    error_message = "The flow log name must default to <vnet_name>-flowlog."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].network_watcher_name == "NetworkWatcher_usgovvirginia" && azurerm_network_watcher_flow_log.vnet[0].resource_group_name == "NetworkWatcherRG"
    error_message = "The flow log must use the given Network Watcher and its resource group."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].storage_account_id == var.flow_log.storage_account_id
    error_message = "The flow log must write to the given storage account."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].enabled == true && azurerm_network_watcher_flow_log.vnet[0].version == 2
    error_message = "The flow log must be enabled and use format version 2."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].retention_policy[0].enabled == true && azurerm_network_watcher_flow_log.vnet[0].retention_policy[0].days == 90
    error_message = "Retention must be enabled and default to 90 days."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].enabled == true
    error_message = "Traffic analytics must be enabled."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].workspace_id == var.flow_log.log_analytics_workspace_id && azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].workspace_region == var.flow_log.log_analytics_workspace_region && azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].workspace_resource_id == var.flow_log.log_analytics_workspace_resource_id
    error_message = "Traffic analytics must use the given workspace GUID, region and resource ID."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].interval_in_minutes == 60
    error_message = "The traffic analytics interval must default to 60 minutes."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].tags == tomap({ Function = "Networking", Region = "usgovvirginia" })
    error_message = "The flow log must carry the merged module tags."
  }

  assert {
    condition     = output.flow_log_id == azurerm_network_watcher_flow_log.vnet[0].id && output.flow_log_id != null
    error_message = "flow_log_id must return the flow log ID when flow_log is set."
  }
}

run "flow_log_overrides_apply" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
      name                                = "custom-flowlog"
    }
    flow_log_retention_days                        = 0
    flow_log_traffic_analytics_interval_in_minutes = 10
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].name == "custom-flowlog"
    error_message = "A caller-supplied name must be used."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].retention_policy[0].days == 0
    error_message = "Retention of 0 (keep indefinitely) must be accepted and passed through."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.vnet[0].traffic_analytics[0].interval_in_minutes == 10
    error_message = "An interval of 10 minutes must be accepted and passed through."
  }
}

run "flow_log_retention_below_90_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
    flow_log_retention_days = 30
  }

  expect_failures = [var.flow_log_retention_days]
}

run "flow_log_interval_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
    flow_log_traffic_analytics_interval_in_minutes = 15
  }

  expect_failures = [var.flow_log_traffic_analytics_interval_in_minutes]
}

run "flow_log_workspace_resource_id_as_guid_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  expect_failures = [var.flow_log]
}

run "flow_log_bad_storage_id_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  expect_failures = [var.flow_log]
}

run "flow_log_empty_watcher_name_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = " "
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  expect_failures = [var.flow_log]
}

run "flow_log_bad_workspace_resource_id_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  expect_failures = [var.flow_log]
}

run "flow_log_bad_name_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testflowlogs"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
      name                                = "-bad-name-"
    }
  }

  expect_failures = [var.flow_log]
}

run "flow_log_storage_id_wrong_type_rejected" {
  command = plan

  variables {
    flow_log = {
      network_watcher_name                = "NetworkWatcher_usgovvirginia"
      network_watcher_resource_group_name = "NetworkWatcherRG"
      storage_account_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_id          = "11111111-1111-1111-1111-111111111111"
      log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      log_analytics_workspace_region      = "usgovvirginia"
    }
  }

  expect_failures = [var.flow_log]
}
