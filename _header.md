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
        subnet_delegations = ["Microsoft.DBforPostgreSQL/flexibleServers"]
        enforce_private_link_endpoint_network_policies = true
      }
    }
  }

  #Log Analytics 
  diag_log_analytics_id = data.terraform_remote_state.core.outputs.core_la_id
  
  #Attach Vnet to Private DNS zone
  private_dns_zone_id = data.terraform_remote_state.core.outputs.core_map_private_dns_zone_ids #Value is an input of a Map of Private DNS zone names to their resource IDs

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

