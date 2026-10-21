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

variable "flow_log" {
  description = "Turns on a VNet flow log with traffic analytics when set. Default null (off). Needs an existing Network Watcher in the VNet region, a Standard GPv2 storage account in the VNet region, and a Log Analytics workspace. log_analytics_workspace_id is the workspace GUID (customer ID), not its resource ID. name defaults to <vnet_name>-flowlog."
  type = object({
    network_watcher_name                = string
    network_watcher_resource_group_name = string
    storage_account_id                  = string
    log_analytics_workspace_id          = string
    log_analytics_workspace_resource_id = string
    log_analytics_workspace_region      = string
    name                                = optional(string)
  })
  default = null

  validation {
    condition     = var.flow_log == null ? true : length(trimspace(var.flow_log.network_watcher_name)) > 0 && length(trimspace(var.flow_log.network_watcher_resource_group_name)) > 0 && length(trimspace(var.flow_log.log_analytics_workspace_region)) > 0
    error_message = "flow_log.network_watcher_name, network_watcher_resource_group_name and log_analytics_workspace_region must not be empty."
  }

  validation {
    condition     = var.flow_log == null ? true : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Storage/storageAccounts/[^/]+$", var.flow_log.storage_account_id))
    error_message = "flow_log.storage_account_id must be a storage account resource ID."
  }

  validation {
    condition     = var.flow_log == null ? true : can(regex("(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.flow_log.log_analytics_workspace_id))
    error_message = "flow_log.log_analytics_workspace_id must be the workspace GUID, not its resource ID."
  }

  validation {
    condition     = var.flow_log == null ? true : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.flow_log.log_analytics_workspace_resource_id))
    error_message = "flow_log.log_analytics_workspace_resource_id must be a Log Analytics workspace resource ID."
  }

  validation {
    condition     = var.flow_log == null ? true : (var.flow_log.name == null ? true : can(regex("^[^\\W_]$|^[^\\W_][\\w.\\-]{0,78}[\\w]$", var.flow_log.name)))
    error_message = "flow_log.name must be 1 to 80 characters, start with a letter or digit, end with a word character, and use only word characters, '.', '-' or '_'."
  }
}

variable "flow_log_retention_days" {
  description = "Days to keep flow log records in the storage account when flow_log is set. 0 keeps them indefinitely. Otherwise at least 90."
  type        = number
  default     = 90
  nullable    = false

  validation {
    condition     = floor(var.flow_log_retention_days) == var.flow_log_retention_days && (var.flow_log_retention_days == 0 || var.flow_log_retention_days >= 90)
    error_message = "flow_log_retention_days must be a whole number: 0 (keep indefinitely) or at least 90."
  }
}

variable "flow_log_traffic_analytics_interval_in_minutes" {
  description = "Traffic analytics processing interval in minutes when flow_log is set. 10 or 60."
  type        = number
  default     = 60
  nullable    = false

  validation {
    condition     = contains([10, 60], var.flow_log_traffic_analytics_interval_in_minutes)
    error_message = "flow_log_traffic_analytics_interval_in_minutes must be 10 or 60."
  }
}
