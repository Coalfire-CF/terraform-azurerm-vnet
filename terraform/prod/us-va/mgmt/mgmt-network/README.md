# Management Network Deployment

This deploys the Management VNet and it's subnets

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