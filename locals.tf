# locals {
#   azurerm_subnets = {
#     for index, subnet in azurerm_subnet.main :
#     subnet.name => subnet.id
#   }
# }
