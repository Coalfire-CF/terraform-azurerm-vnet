module "mgmt_resource_naming_va" {
  source                 = "Azure/naming/azurerm"
  prefix                 = ["${local.resource_prefix_mgmt}"]
  unique-include-numbers = false
}

module "app_resource_naming_va" {
  source                 = "Azure/naming/azurerm"
  prefix                 = ["${local.resource_prefix_app}"]
  unique-include-numbers = false
}

module "mgmt-vnet" {
  source              = "../../../../modules/azurerm-vnet"
  vnet_name           = "${module.mgmt_resource_naming_va.virtual_network.name}-mgmt"
  resource_group_name = data.terraform_remote_state.setup.outputs.network_rg_name
  address_space       = ["${var.mgmt_network_cidr}"]
  subnets             = {
    "${module.mgmt_resource_naming_va.subnet.name}-iam" = {
      address_prefix           = cidrsubnet("${var.mgmt_network_cidr}", 8, 0) #cidrsubnet(prefix, newbits, netnum)
      subnet_service_endpoints = [
        "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"
      ]
    }
    "${module.mgmt_resource_naming_va.subnet.name}-cicd" = {
      address_prefix           = cidrsubnet("${var.mgmt_network_cidr}", 8, 1) #cidrsubnet(prefix, newbits, netnum)
      subnet_service_endpoints = [
        "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"
      ]
    }
    "${module.mgmt_resource_naming_va.subnet.name}-secops" = {
      address_prefix           = cidrsubnet("${var.mgmt_network_cidr}", 8, 2) #cidrsubnet(prefix, newbits, netnum)
      subnet_service_endpoints = [
        "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"
      ]
    }
    "${module.mgmt_resource_naming_va.subnet.name}-be" = {
      address_prefix           = cidrsubnet("${var.mgmt_network_cidr}", 8, 3) #cidrsubnet(prefix, newbits, netnum)
      subnet_service_endpoints = [
        "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"
      ]
    }
    "${module.mgmt_resource_naming_va.subnet.name}-aks" = {
      address_prefix           = cidrsubnet("${var.mgmt_network_cidr}", 4, 8) #cidrsubnet(prefix, newbits, netnum)
      subnet_service_endpoints = [
        "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"
      ]
    }
  }

  diag_log_analytics_id = data.terraform_remote_state.core.outputs.core_la_id

  #Attach Vnet to Private DNS zone
  private_dns_zone_id = data.terraform_remote_state.core.outputs.core_private_dnz_zone_id

  #Note: DNS servers should be left to Azure default until the DC's are up. Otherwise the VM's will fail to get DNS to download scripts from storage accounts.
  #dns_servers   = concat(data.terraform_remote_state.usgv-ad.outputs.ad_dc1_ip, data.terraform_remote_state.usgv-ad.outputs.ad_dc2_ip)
  regional_tags = var.regional_tags
  global_tags   = var.global_tags
  tags          = {
    Function = "Networking"
    Plane    = "Management"
  }
}


