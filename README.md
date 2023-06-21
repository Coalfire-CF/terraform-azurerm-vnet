# MSCI Azure VNet

## Description

This Terraform module deploys a Virtual Network in Azure with a subnet or a set of subnets passed in as input parameters.

## Resource List

- Vnet
- Subnets
- NSG and route table associations
- Monitor diagnostic setting

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| name | The virtual network name | string | N/A | yes |
| resource_group_name | The name of the resource group in which to create the resource in | string | N/A | yes |
| location | The Azure location/region to create resources in | string | N/A | yes |
| address_space | The address space that is used by the virtual network | string | N/A | yes |
| subnets | List of maps with Subnet names and their configuration | [{subnet_name=string,address_prefix=string,nsg_id=string,subnet_service_endpoints=optional(list(string)),subnet_delegations=optional(map(any)),private_endpoint_network_policies_enabled=optional(bool),private_link_service_network_policies_enabled=optional(bool),route_tables_id=optional(string)}] | N/A | yes |
| tags | The tags to associate with your network and subnets | map(string) | N/A | yes |
| diag_log_analytics_id | ID of the Log Analytics Workspace diagnostic logs should be sent to | string | N/A | yes |
| dns_servers | The DNS servers to be used with VNet | list(string) | [] | no |
| private_dns_zone_ids | List of Private DNS Zone IDs to link with the vnet | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the VNet |
| name | The Name of the VNet |
| resource_group_name | The Resource Group Name of the VNet |
| address_space | The address space of the VNet | 
| subnet_ids | Map with the IDs of the subnets created inside the VNet |
| addresses | Map with the cidr of subnets created inside the VNet |

## Product Limitations

- Network policies, like network security groups (NSG), are not supported for Private Link Endpoints or Private Link Services. In order to deploy a Private Link Endpoint on a given subnet, you must set the `private_endpoint_network_policies_enabled` attribute to `false`.
- In order to deploy a Private Link Service on a given subnet, you must set the `private_link_service_network_policies_enabled` attribute to `false`.

## Usage
This module can be called as outlined below. 
- Create a `local` folder under `terraform/azure`.
- Create a `main.tf` file in the `local` folder. 
- Copy the code below into `main.tf`.
- From the `terraform/azure/local` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.


```hcl
provider "azurerm" {
  features {}
}

module "vnet" {
  source = "../modules/msci-azure-vnet"

  name                  = "mgmt-demo-us-vnet"
  resource_group_name   = "mgmt-demo-us-rg"
  location              = "eastus"
  diag_log_analytics_id = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.OperationalInsights/workspaces/<log_analytics_workspace_name>"
  address_space         = ["10.0.0.0/16"]

  subnets = [
    {
      subnet_name    = "mgmt-demo-us-common-sn"
      address_prefix = "10.1.0.0/24"
      nsg_id         = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Network/networkSecurityGroups/<nsg_name>"
    },
    {
      subnet_name    = "mgmt-demo-us-private_link-sn"
      address_prefix = "10.2.0.0/24"
      subnet_delegations = {
        "Microsoft.DBforPostgreSQL/flexibleServers" = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
      private_endpoint_network_policies_enabled = false
      nsg_id                                    = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Network/networkSecurityGroups/<nsg_name>"
    }
  ]

  tags = {
    Plane       = "Core"
    Environment = "dev"
  }
}
```