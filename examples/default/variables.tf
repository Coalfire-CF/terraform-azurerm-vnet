variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
  default     = "example-vnet"
}

variable "resource_group_name" {
  description = "Name of an existing resource group for the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address space of the virtual network. Subnets are carved from the first entry."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "diag_log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace that receives diagnostic logs and metrics."
  type        = string
}

variable "core_private_dns_zone_ids" {
  description = "Map of existing private DNS zone names to their resource IDs. The VNet is linked to each one."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the virtual network and DNS zone links."
  type        = map(string)
  default     = {}
}
