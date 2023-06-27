module "diag" {
  source                = "github.com/Coalfire-CF/ACE-Azure-Diagnostics"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_virtual_network.vnet.id
  resource_type         = "vnet"
}
