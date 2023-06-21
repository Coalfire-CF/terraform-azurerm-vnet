output "id" {
  description = "The ID of the VNet"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "The Name of the VNet"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "The address space of the VNet"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map with the IDs of the subnets created inside the VNet"
  value       = local.azurerm_subnets
}

output "subnet_addresses" {
  description = "Map with the cidr of subnets created inside the VNet"
  value = {
    for index, subnet in azurerm_subnet.main :
    subnet.name => subnet.address_prefixes.0
  }
}

output "resource_group_name" {
  description = "The Resource Group Name of the VNet"
  value       = azurerm_virtual_network.main.resource_group_name
}
