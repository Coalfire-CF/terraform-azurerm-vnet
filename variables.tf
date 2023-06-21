variable "name" {
  description = "The virtual network name."
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resource in."
}

variable "location" {
  description = "The Azure location/region to create resources in."
  type        = string
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
}

variable "subnets" {
  # Due to Terraform limitation = element types must all match for conversion to list, type is commented out but this shows what module expects
  #   type = list(object({
  #     subnet_name                                   = string
  #     address_prefix                                = string
  #     nsg_id                                        = string
  #     subnet_service_endpoints                      = optional(list(string))
  #     subnet_delegations                            = optional(map(any))
  #     private_endpoint_network_policies_enabled     = optional(bool)
  #     private_link_service_network_policies_enabled = optional(bool)
  #     route_tables_id                               = optional(string)
  #   }))
  description = "List of maps with Subnet names and their configuration"
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with VNet."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "List of Private DNS Zone IDs to link with the vnet."
  default     = []
}

variable "diag_log_analytics_id" {
  description = "ID of the Log Analytics Workspace diagnostic logs should be sent to"
  type        = string
}
