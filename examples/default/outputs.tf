output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.vnet.vnet_id
}

output "vnet_subnets" {
  description = "Map of subnet name to subnet resource ID."
  value       = module.vnet.vnet_subnets
}
