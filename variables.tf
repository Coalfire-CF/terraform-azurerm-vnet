variable "vnet_name" {
  description = "Name of the vnet to create"
  type        = string
  default     = "acctvnet"
}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
  default     = ["10.0.0.0/16"]
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with VNet."
  type        = list(string)
  default     = []
}
variable "subnets" {
  description = "Map of subnet name to settings. Defaults follow Azure Verified Modules: network policies apply to private endpoints, private link service policies stay on, and default outbound internet access is off. Turning default_outbound_access_enabled on gives VMs in the subnet implicit internet egress through an Azure-owned IP. Setting private_endpoint_network_policies to Disabled means NSGs and route tables do not apply to private endpoints in the subnet. A subnet that hosts a Private Link Service must set private_link_service_network_policies_enabled to false."
  type = map(object({
    address_prefix                                = string
    subnet_service_endpoints                      = optional(list(string), [])
    subnet_delegations                            = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    default_outbound_access_enabled               = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for s in values(var.subnets) :
      contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], s.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled or RouteTableEnabled."
  }
}

variable "nsg_ids" {
  description = "A map of subnet name to Network Security Group IDs"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.nsg_ids) : contains(keys(var.subnets), k)])
    error_message = "Every nsg_ids key must be a subnet name in subnets."
  }
}

variable "route_tables_ids" {
  description = "A map of subnet name to Route table ids"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.route_tables_ids) : contains(keys(var.subnets), k)])
    error_message = "Every route_tables_ids key must be a subnet name in subnets."
  }
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}

variable "regional_tags" {
  type        = map(string)
  description = "Regional level tags"
  default     = {}
}

variable "global_tags" {
  type        = map(string)
  description = "Global level tags"
  default     = {}
}

variable "core_private_dns_zone_ids" {
  description = "Map of core Azure Private DNS zone names to their resource IDs."
  type        = map(string)
  default     = {}
}

variable "create_private_dns_zone" {
  description = "When true, link the VNet to every zone in core_private_dns_zone_ids. The zones must already exist."
  type        = bool
  default     = true
}

variable "diag_log_analytics_id" {
  description = "ID of the Log Analytics Workspace diagnostic logs should be sent to"
  type        = string
}