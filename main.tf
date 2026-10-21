data "azurerm_resource_group" "vnet" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.vnet.name
  location            = data.azurerm_resource_group.vnet.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = local.tags
}

resource "azurerm_subnet" "subnet" {
  #checkov:skip=CKV2_AZURE_31:NSGs are caller inputs (nsg_ids), attached by azurerm_subnet_network_security_group_association.
  for_each                                      = var.subnets
  name                                          = each.key
  resource_group_name                           = data.azurerm_resource_group.vnet.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = [each.value.address_prefix]
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled

  # azurerm 5.x replaced the service_endpoints list with service_endpoint blocks.
  # The input stays a list of service names, so callers do not change.
  dynamic "service_endpoint" {
    for_each = each.value.subnet_service_endpoints
    content {
      service = service_endpoint.value
    }
  }

  dynamic "delegation" {
    for_each = each.value.subnet_delegations
    content {
      name = delegation.value

      service_delegation {
        name    = delegation.value
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
  }
}

locals {
  azurerm_subnets = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
  tags = merge(var.tags, var.regional_tags, var.global_tags)
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each                  = var.nsg_ids
  subnet_id                 = local.azurerm_subnets[each.key]
  network_security_group_id = each.value
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each       = var.route_tables_ids
  route_table_id = each.value
  subnet_id      = local.azurerm_subnets[each.key]
}


resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  for_each = var.create_private_dns_zone ? var.core_private_dns_zone_ids : {}

  # sanitize the zone name: replace '.' with '-' for the link name
  name = "${azurerm_virtual_network.vnet.name}-${replace(each.key, ".", "-")}"

  private_dns_zone_id  = each.value
  virtual_network_id   = azurerm_virtual_network.vnet.id
  registration_enabled = false
  tags                 = local.tags
}

module "diag" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics?ref=v3.0.0"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_virtual_network.vnet.id
  resource_type         = "vnet"
}

# VNet flow log with traffic analytics. Off unless flow_log is set (D2: needs a
# caller-supplied Network Watcher, storage account and workspace). Azure no
# longer allows new NSG flow logs.
resource "azurerm_network_watcher_flow_log" "vnet" {
  count = var.flow_log == null ? 0 : 1

  name                 = coalesce(var.flow_log.name, "${azurerm_virtual_network.vnet.name}-flowlog")
  network_watcher_name = var.flow_log.network_watcher_name
  resource_group_name  = var.flow_log.network_watcher_resource_group_name
  target_resource_id   = azurerm_virtual_network.vnet.id
  storage_account_id   = var.flow_log.storage_account_id
  enabled              = true
  version              = 2
  tags                 = local.tags

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.flow_log.log_analytics_workspace_id
    workspace_region      = var.flow_log.log_analytics_workspace_region
    workspace_resource_id = var.flow_log.log_analytics_workspace_resource_id
    interval_in_minutes   = var.flow_log_traffic_analytics_interval_in_minutes
  }
}
