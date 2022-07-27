# Azure Vnet

Vnet and subnet Deployment

## Description

This Terraform module deploys a Virtual Network in Azure with a subnet or a set of subnets passed in as input parameters.

The module does not create nor expose a security group. This would need to be defined separately as additional security rules on subnets in the deployed network.

## Resource List

- Vnet
- Subnets
- NSG and route table associations

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| resource_group_name | Name of the resource group to be imported | string | N/A | yes |
| subnets | Map of maps with Subnet names and their configuration | map | N/A | yes |
| tags | The tags to associate with your network and subnets | map(string) | N/A | yes |
| diag_log_analytics_id | ID of the Log Analytics Workspace diagnostic logs should be sent to | string | N/A | yes |
| vnet_name | Name of the vnet to create | string | acctvnet | no |
| address_space | The address space that is used by the virtual network | string | 10.0.0.0/16 | no |
| dns_servers | The DNS servers to be used with VNet | list(string) | [] | no |
| nsg_ids | A map of subnet name to Network Security Group IDs | map(string) | {} | no |
| route_table_ids | A map of subnet name to Route table ids | map(string) | {} | no |
| regional_tags | Regional level tags | map(string) | {} | no |
| global_tags | Global level tags | map(string) | {} | no |
| private_dns_zone_id | The ID of the Private DNS Zone. If passed, it will create a vnet link with the private DNS zone | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of Redis Cache Instance |
| vnet_name | The Name of the newly created VNet |
| vnet_location | The location of the newly created VNet |
| vnet_address_space | The address space of the newly created VNet | 
| vnet_subnets | Map with the ids of subnets created inside the new VNet |
| subnet_addresses | Map with the cidr of subnets created inside the new VNet |

## Product Limitations

- Network policies, like network security groups (NSG), are not supported for Private Link Endpoints or Private Link Services. In order to deploy a Private Link Endpoint on a given subnet, you must set the enforce_private_link_endpoint_network_policies attribute to true.

## Usage

```hcl
module "app-vnet" {
  source                   = "../azurerm-vnet"
  vnet_name                = "app-vnet"
  resource_group_name      = local.network_resource_group_name
  address_space            = "10.2.0.0/16"
  diag_log_analytics_id    = var.diag_la_id

  subnets = {
    "subnet1" = {
      address_prefix = "10.2.0.0/19"
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    "subnet2" = {
      address_prefix = "10.2.32.0/26"
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      subnet_delegations = ["Microsoft.Databricks/workspaces"]
    }
    "subnet3" = {
      address_prefix = "10.2.32.64/26"
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      subnet_delegations = ["Microsoft.Databricks/workspaces"]
    }
  }

  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  depends_on = [azurerm_resource_group.example]

  #OPTIONAL

  route_tables_ids = {
    subnet1 = azurerm_route_table.example.id
    subnet2 = azurerm_route_table.example.id
    subnet3 = azurerm_roiute_table.example.id
  }

  nsg_ids = {
    subnet1 = azurerm_network_security_group.ssh.id
    subnet2 = azurerm_network_security_group.ssh.id
    subnet3 = azurerm_network_security_group.ssh.id
  }

}
```