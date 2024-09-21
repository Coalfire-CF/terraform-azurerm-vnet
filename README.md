![Coalfire](coalfire_logo.png)

# terraform-azurerm-vnet

Repository for Azure VNet Module code. This repo should be used for Azure project to deploy VNets and subnets in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP Framework.

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Description

- Cloud(s) supported: Azure Government & Commercial
- FedRAMP Compliance Support: FR Mod/High
- DoD Compliance Support: {IL4/5}

## Dependencies

- Security Core
- Region Setup

## Created Resources

| Resource | Description |
|------|-------------|
| Virtual Network | |
| Subnet | Public /24 network |
| Subnet | IAM /24 network |
| Subnet | CICD /24 network |
| Subnet | SecOps /24 network |
| Subnet | SIEM /24 network |
| Subnet | Monitor /24 network |
| Subnet | Bastion /24 network |
| Subnet | AzureFireWallSubnet /24 network |
| Subnet | PrivateEndpoint /24 network |
| Subnet | Postgresql /24 network |

## Code updates

- Change directory to the `mgmt-network` folder.
- In the `mgmt.tf` file update the name and number of subnets as needed in the `subnet_addrs` module. Optionally add additional subnet blocks with the appropiate `subnet_service_endpoints` and `subnet_delegations`.
- If you need to add or remove Service Endpoints, do so in the `subnet_service_endpoints` block. See <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet> for Service Endpoint options.
- For the initial deployment, ensure the `dns_servers` line is commented out until the Domain controllers are online. Once the DC's are online uncomment and rerun an `apply`.

`tstate.tf` Update to the appropriate version and storage accounts, see sample

```hcl
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.45.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "prod-mp-core-rg"
    storage_account_name = "prodmpsatfstate"
    container_name       = "tfstatecontainer"
    environment          = "usgovernment"
    key                  = "network.tfstate"
  }
}
```

## Deployment steps

This module can be called as outlined below.

- Change directories to the `mgmt/mgmt-network` directory.
- From the `terraform/azure/mgmt/mgmt-network` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.

## Usage

```hcl
provider "azurerm" {
  features {}
}


module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.mgmt_network_cidr
  networks = [
    {
      name     = "${local.resource_prefix}-public-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-iam-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-cicd-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-secops-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-siem-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-monitor-sn-1"
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-bastion-sn-1"
      new_bits = 8
    },
    {
      name     = "AzureFirewallSubnet" #Per Azure docs, The Management Subnet used for the Firewall must have the name AzureFirewallManagementSubnet and the subnet mask must be at least a /26.
      new_bits = 8
    },
    {
      name     = "${local.resource_prefix}-pe-sn-1"
      new_bits = 8
    }
    ,
    {
      name     = "${local.resource_prefix}-psql-sn-1"
      new_bits = 8
    }
  ]
}

module "mgmt-vnet" {
  source              = "github.com/Coalfire-CF/ACE-Azure-Vnet?ref=module"
  vnet_name           = "${local.resource_prefix}-network-vnet"
  resource_group_name = data.terraform_remote_state.setup.outputs.network_rg_name
  address_space       = [module.subnet_addrs.base_cidr_block]
  subnets = {
    "${local.resource_prefix}-public-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-public-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    "${local.resource_prefix}-iam-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-iam-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    "${local.resource_prefix}-cicd-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-cicd-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }

    "${local.resource_prefix}-secops-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-secops-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    "${local.resource_prefix}-siem-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-siem-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    "${local.resource_prefix}-monitor-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-monitor-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    "${local.resource_prefix}-bastion-sn-1" = {
      address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-bastion-sn-1"]
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

      "AzureFirewallSubnet" = {
        address_prefix           = module.subnet_addrs.network_cidr_blocks["AzureFirewallSubnet"]
        subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      }

      "${local.resource_prefix}-pe-sn-1" = {
        address_prefix                                 = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-pe-sn-1"]
        subnet_service_endpoints                       = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql", "Microsoft.ContainerRegistry"]
        enforce_private_link_endpoint_network_policies = true
      }

      "${local.resource_prefix}-psql-sn-1" = {
        address_prefix           = module.subnet_addrs.network_cidr_blocks["${local.resource_prefix}-psql-sn-1"]
        subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"]
        subnet_delegations = {
          "Microsoft.DBforPostgreSQL/flexibleServers" = ["Microsoft.Sql"]
        }
        enforce_private_link_endpoint_network_policies = true
      }
    }
  }

  diag_log_analytics_id = data.terraform_remote_state.core.outputs.core_la_id
  # storage_account_flowlogs_id     = data.terraform_remote_state.setup.outputs.storage_account_flowlogs_id
  #network_watcher_name            = data.terraform_remote_state.setup.outputs.network_watcher_name

  #Attach Vnet to Private DNS zone
  private_dns_zone_id = data.terraform_remote_state.core.outputs.core_private_dns_zone_id.0

  #Note: DNS servers should be left to Azure default until the DC's are up. Otherwise the VM's will fail to get DNS to download scripts from storage accounts.
  #dns_servers   = concat(data.terraform_remote_state.usgv-ad.outputs.ad_dc1_ip, data.terraform_remote_state.usgv-ad.outputs.ad_dc2_ip)
  #regional_tags = var.regional_tags
  #global_tags   = merge(var.global_tags, local.global_local_tags)
  tags = {
    Function = "Networking"
    Plane    = "Management"
  }
}

```


## Next steps

Application VNet (terraform/prod/{region}/mgmt/mgmt-network)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_diag"></a> [diag](#module\_diag) | github.com/Coalfire-CF/terraform-azurerm-diagnostics | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_zone_virtual_network_link.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_resource_group.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | The address space that is used by the virtual network. | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| <a name="input_diag_log_analytics_id"></a> [diag\_log\_analytics\_id](#input\_diag\_log\_analytics\_id) | ID of the Log Analytics Workspace diagnostic logs should be sent to | `string` | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The DNS servers to be used with VNet. | `list(string)` | `[]` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global level tags | `map(string)` | `{}` | no |
| <a name="input_nsg_ids"></a> [nsg\_ids](#input\_nsg\_ids) | A map of subnet name to Network Security Group IDs | `map(string)` | `{}` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The ID of the Private DNS Zone. | `string` | `null` | no |
| <a name="input_regional_tags"></a> [regional\_tags](#input\_regional\_tags) | Regional level tags | `map(string)` | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group to be imported. | `string` | n/a | yes |
| <a name="input_route_tables_ids"></a> [route\_tables\_ids](#input\_route\_tables\_ids) | A map of subnet name to Route table ids | `map(string)` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of maps with Subnet names and their configuration | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to associate with your network and subnets. | `map(string)` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the vnet to create | `string` | `"acctvnet"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnet_addresses"></a> [subnet\_addresses](#output\_subnet\_addresses) | Map with the cidr of subnets created inside the new VNet |
| <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space) | The address space of the newly created VNet |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The id of the newly created VNet |
| <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location) | The location of the newly created VNet |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The Name of the newly created VNet |
| <a name="output_vnet_subnets"></a> [vnet\_subnets](#output\_vnet\_subnets) | The ids of subnets created inside the new VNet |
<!-- END_TF_DOCS -->

## Contributing

[Start Here](CONTRIBUTING.md)

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)

## Contact Us

[Coalfire](https://coalfire.com/)

### Copyright

Copyright © 2023 Coalfire Systems Inc.