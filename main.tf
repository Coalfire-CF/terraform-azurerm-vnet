resource "azurerm_virtual_network" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  for_each                                      = { for subnet in var.subnets : subnet.subnet_name => subnet }
  name                                          = each.value.subnet_name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.main.name
  address_prefixes                              = [each.value.address_prefix]
  service_endpoints                             = try(each.value.subnet_service_endpoints, null)
  private_endpoint_network_policies_enabled     = try(each.value.private_endpoint_network_policies_enabled, true)
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, true)


  dynamic "delegation" {
    for_each = try(each.value.subnet_delegations, {})
    content {
      name = delegation.key

      service_delegation {
        name    = delegation.key
        actions = delegation.value
      }
    }
  }
}

#NSG is required
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each                  = { for subnet in var.subnets : subnet.subnet_name => subnet if can(subnet.nsg_id) }
  subnet_id                 = local.azurerm_subnets[each.value.subnet_name]
  network_security_group_id = each.value.nsg_id
}

#Route table is optional
resource "azurerm_subnet_route_table_association" "main" {
  for_each       = { for subnet in var.subnets : subnet.subnet_name => subnet if can(subnet.route_table_id) }
  subnet_id      = local.azurerm_subnets[each.value.subnet_name]
  route_table_id = each.value.route_table_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = toset(var.private_dns_zone_ids)
  name                  = "${azurerm_virtual_network.main.name}-link"
  resource_group_name   = element(split("/", each.value), 4)                                  # get the resource group name
  private_dns_zone_name = element(split("/", each.value), length(split("/", each.value)) - 1) # get the zone name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}

module "diag" {
  source                = "../msci-azure-diagnostic"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_virtual_network.main.id
  resource_type         = "vnet"
}
