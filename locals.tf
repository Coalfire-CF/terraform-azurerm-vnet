# locals {
#   azurerm_subnets = {
#     for index, subnet in azurerm_subnet.main :
#     subnet.name => subnet.id
#   }
# }
locals (
  tags = merge(var.regional_tags, var.global_tags, {
  Function = "Networking"
  Plane    = "Core"
  }) 
)