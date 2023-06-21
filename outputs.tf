output "vnet_id" {
  description = "The id of the newly created VNet"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The Name of the newly created VNet"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  description = "The location of the newly created VNet"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_address_space" {
  description = "The address space of the newly created VNet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "vnet_subnets" {
  description = "The ids of subnets created inside the new VNet"
  value       = local.azurerm_subnets
}

output "subnet_addresses" {
  description = "Map with the cidr of subnets created inside the new VNet"
  #value       = values(azurerm_subnet.subnet)[*].address_prefixes
  value = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.address_prefixes.0
  }
}
