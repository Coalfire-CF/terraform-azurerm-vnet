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
  for_each                                       = var.subnets
  name                                           = each.key
  resource_group_name                            = data.azurerm_resource_group.vnet.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [each.value.address_prefix]
  service_endpoints                              = try(each.value.subnet_service_endpoints, null)
  enforce_private_link_endpoint_network_policies = try(each.value.enforce_private_link_endpoint_network_policies, false)
  enforce_private_link_service_network_policies  = try(each.value.enforce_private_link_service_network_policies, false)

  dynamic "delegation" {
    for_each = try(each.value.subnet_delegations, [])
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
  count                 = var.private_dns_zone_id != null ? 1 : 0
  name                  = "${azurerm_virtual_network.vnet.name}-link"
  resource_group_name   = element(split("/", var.private_dns_zone_id), 4)                                               #get the resource group name
  private_dns_zone_name = element(split("/", var.private_dns_zone_id), length(split("/", var.private_dns_zone_id)) - 1) #get the zone name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
  tags                  = local.tags
}

module "diag" {
  source                = "git@github.com:Coalfire-CF/ACE-Azure-Diagnostics.git?ref=v1.0.1"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_virtual_network.vnet.id
  resource_type         = "vnet"
}