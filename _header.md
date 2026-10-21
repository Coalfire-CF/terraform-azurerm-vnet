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
| Virtual network | One VNet with the given address space and DNS servers. |
| Subnets | One subnet per entry in `subnets`, with service endpoints and delegations. |
| NSG associations | One per entry in `nsg_ids`. The NSGs are caller inputs. |
| Route table associations | One per entry in `route_tables_ids`. The route tables are caller inputs. |
| Private DNS zone VNet links | One per entry in `core_private_dns_zone_ids` when `create_private_dns_zone` is true. The zones must already exist. |
| Diagnostic settings | Sent to `diag_log_analytics_id` through `terraform-azurerm-diagnostics`. |

## Secure defaults

Each subnet in `subnets` gets these defaults. They follow Azure Verified Modules.

- `private_endpoint_network_policies = "Enabled"`. NSGs and route tables apply to private endpoints in the subnet. Set `Disabled` only when you accept that they do not.
- `private_link_service_network_policies_enabled = true`. A subnet that hosts a Private Link Service must set this to `false`.
- `default_outbound_access_enabled = false`. VMs get no implicit internet egress. A subnet that needs egress can set `true`, but prefer a NAT gateway or a firewall route.

NSGs are caller inputs through `nsg_ids`. That is why the module skips checkov `CKV2_AZURE_31` on `azurerm_subnet`.

## Usage

See [`examples/default`](examples/default) for a runnable root with a provider block.

```hcl
module "vnet" {
  source = "git::https://github.com/Coalfire-CF/terraform-azurerm-vnet?ref=v3.0.0"

  vnet_name             = "example-vnet"
  resource_group_name   = "example-network-rg"
  address_space         = ["10.10.0.0/16"]
  diag_log_analytics_id = var.diag_log_analytics_id

  subnets = {
    "app-sn-1" = {
      address_prefix           = "10.10.1.0/24"
      subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    "pe-sn-1" = {
      address_prefix = "10.10.2.0/24"
    }
    "psql-sn-1" = {
      address_prefix     = "10.10.3.0/24"
      subnet_delegations = ["Microsoft.DBforPostgreSQL/flexibleServers"]
    }
  }

  nsg_ids = {
    "app-sn-1" = var.app_nsg_id
  }

  core_private_dns_zone_ids = var.core_private_dns_zone_ids

  tags = {
    Function = "Networking"
  }
}
```
