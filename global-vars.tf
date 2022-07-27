# LOCALS
locals {
  resource_prefix_mgmt = "${var.environment}-mgmt-${var.location_abbreviation}" #prd-mgmt-va
  resource_prefix_app  = "${var.environment}-app-${var.location_abbreviation}" #prd-app-va
  vm_name_prefix_mgmt  = replace(local.resource_prefix_mgmt, "-", "")
  storage_name_prefix  = replace(local.resource_prefix_mgmt, "-", "")
}

#TODO: review and change all vars below as necessary
# VARIABLES
variable "subscription_id" {
  type    = string
  default = ""
}

variable "stage_subscription_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "app_subscription_ids" {
  type    = map(any)
  default = {
  }
}

variable "app_abbreviation" {
  description = "A abbreviation that should be attached to the names of resources"
  type        = string
  default     = ""
}

variable "global_tags" {
  type    = map(string)
  default = {
    Managed_By = "Terraform"
  }
}

variable "azure_cloud" {
  type        = string
  description = "Azure Cloud (Commercial - AzureCloud/Government - AzureUSGovernment)"
  default     = "AzureUSGovernment"
}