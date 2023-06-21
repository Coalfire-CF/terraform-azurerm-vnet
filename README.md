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
