# ACE-Azure-VNet

Repository for Azure VNet Module ACE code. This repo should be used for Azure project to deploy VNets and subnets.

## Description

- Terraform Version: 1.1.7
- Cloud(s) supported: Azure Government & Commercial
- Product Version/License: N/A
- FedRAMP Compliance Support: FR Mod/High
- DoD Compliance Support: {IL4/5}
- Misc Framework Support: N/A
- Launchpad validated version: N/A

## Setup and usage

1. Clone repo to your Azure project directory, path should be 
   1. Module path should be `terraform/modules/azurerm-vnet`
   2. Terraform build path should be `terraform/prod/us-va/mgmt/mgmt-network`
2. Regional vars should be modified to match the proper subnet/vnet values for your build. Resource/vnet/subnet names should also be modified in the code for mgmt.tf
3. The subnets are calculated via terraform `cidrsubnet()` function. This link shows how to use the function
   1. https://www.terraform.io/language/functions/cidrsubnet
   2. Here are some examples too:
      1. ```
         > cidrsubnet("10.0.0.0/16", 8,0)
         "10.0.0.0/24"
         > cidrsubnet("10.0.0.0/16", 8,1)
         "10.0.1.0/24"
         > cidrsubnet("10.0.0.0/16", 8,2)
         "10.0.2.0/24"
         > cidrsubnet("10.0.0.0/16", 8,3)
         "10.0.3.0/24"
         > cidrsubnet("10.0.0.0/16", 4,8)
         "10.0.128.0/20"
         > cidrsubnet("10.254.0.0/16", 10,1020)
         "10.254.255.0/26"
         > cidrsubnet("10.254.0.0/16", 10,1015)
         "10.254.253.192/26"
         > cidrsubnet("10.254.0.0/16", 10,1016)
         "10.254.254.0/26"
         ```
4. You must also have the `terraform/modules/coalfire-diagnostic` module cloned as the azurerm-vnet module utilizes the coalfire-diagnostic module in `azurerm-vnet/main.tf` line 67 to create diag log backends.          
      

### Code Location

Code should be stored in:
   1. Module path should be `terraform/modules/azurerm-vnet`
   2. Terraform build path should be `terraform/prod/us-va/mgmt/mgmt-network`

### Code updates

1. Ensure that your subnet/vnet vars are in regional-vars.tf
2. Ensure your Resource Group names are accurate
3. Ensure the proper subnet_service_endpoints are being allowed per subnet

## Dependencies

- Security Core
- Region Setup

## Code updates

`mgmt.tf`

- Update the name and number of subnets as needed in the `subnet_addrs` module.
- If you need to add or remove Service Endpoints, do so in the `subnet_service_endpoints` block. See <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet> for Service Endpoint options.
- For the initial deployment, ensure the `dns_servers` line is commented out until the Domain controllers are online. Once the DC's are online uncomment and rerun an `apply`.

`tstate.tf` Update to the appropriate version and storage accounts, see sample

```hcl
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.91.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "v1-prod-va-mp-core-rg"
    storage_account_name = "v1prodvampsatfstate"
    container_name       = "vav1tfstatecontainer"
    environment          = "usgovernment"
    key                  = "va-mgmt-network.tfstate"
  }
}
```

## Deployment steps

Change directory to the `mgmt/mgmt-network` folder in the primary region

Run `terraform init` to initialize modules and remote state.

Run `terraform plan` and evaluate the plan is expected.

Run `terraform apply` to deploy.

Update the `remote-data.tf` file to add the region setup state key

Rerun `terraform apply` to update all changes

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

## Next steps

Application VNet (terraform/prod/{region}/mgmt/mgmt-network)

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|

## Outputs

| Name | Description |
|------|-------------|
| usgv_mgmt_vnet_id | The id of the management vnet |
| usgv_mgmt_vnet_name | The name of the management vnet |
| usgv_mgmt_vnet_subnet_ids | The ids of subnets created inside the new vnet |

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
| <a name="module_diag"></a> [diag](#module\_diag) | github.com/Coalfire-CF/ACE-Azure-Diagnostics | n/a |

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
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | The address space that is used by the virtual network. | `list(string)` | <pre>[<br>  "10.0.0.0/16"<br>]</pre> | no |
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