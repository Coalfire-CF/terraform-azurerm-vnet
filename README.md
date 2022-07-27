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

## Issues

Bug fixes and enhancements are managed, tracked, and discussed through the GitHub issues on this repository.

Issues should be flagged appropriately.

- Bug
- Enhancement
- Documentation
- Code

### Bugs

Bugs are problems that exist with the technology or code that occur when expected behavior does not match implementation.
For example, spelling mistakes on a dashboard.

Use the Bug fix template to describe the issue and expected behaviors.

### Enhancements

Updates and changes to the code to support additional functionality, new features or improve engineering or operations usage of the technology.
For example, adding a new widget to a dashboard to report on failed backups is enhancement.

Use the Enhancement issue template to request enhancements to the codebase. Enhancements should be improvements that are applicable to wide variety of clients and projects. One of updates for a specific project should be handled locally. If you are unsure if something qualifies for an enhancement contact the repository code owner.

### Pull Requests

Code updates ideally are limited in scope to address one enhancement or bug fix per PR. The associated PR should be linked to the relevant issue.

### Code Owners

- Primary Code owner: Douglas Francis (@douglas-f)
- Backup Code owner: Kourosh Mobl (@kourosh-forti-hands)

The responsibility of the code owners is to approve and Merge PR's on the repository, and generally manage and direct issue discussions.

## Repository Settings

Settings that should be applied to repos

### Branch Protection

#### main Branch

- Require a pull request before merging
- Require Approvals
- Dismiss stale pull requests approvals when new commits are pushed
- Require review from Code Owners

#### other branches

- add as needed

### GitHub Actions

Future state. There are current initiatives for running CI/CD tooling as GitHub actions.
