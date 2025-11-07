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
  private_endpoint_network_policies              = try(each.value.private_endpoint_network_policies, "Disabled")
  private_link_service_network_policies_enabled  = try(each.value.private_link_service_network_policies_enabled, false)

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
  for_each = var.create_private_dns_zone ? var.core_private_dns_zone_ids : {}

  # sanitize the zone name: replace '.' with '-' for the link name
  name = "${azurerm_virtual_network.vnet.name}-${replace(each.key, ".", "-")}"

  resource_group_name   = element(split("/", each.value), 4)
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
}

module "diag" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics?ref=v1.1.4"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_virtual_network.vnet.id
  resource_type         = "vnet"
}
