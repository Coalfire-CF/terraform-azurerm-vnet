provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  environment     = "usgovernment"
}

variable "location" {
  default = "usgovvirginia"
}

variable "location_dr" {
  default = "usgovtexas"
}

variable "location_abbreviation" {
  default = "va"
}

variable "regional_tags" {
  type    = map(string)
  default = {
    Environment = "Production"
    Region      = "USGV"
  }
}

variable "environment" {
  type    = string
  default = "prd"
}

#####################
#####################
################# removing this in favor of using the TF cidr tools and the 'mgmt_network_cidr'
# variable "ip_network_mgmt" {
#   type    = string
#   default = "10.0"
# }
#TODO: change all Network Vars
variable "mgmt_network_cidr" {
  type    = string
  default = "10.0.0.0/16"
}


#####################
#####################
################# removing this in favor of using the TF cidr tools and the 'app_network_cidr'
# variable "ip_network_app" {
#   type    = string
#   default = "10.1"
# }

variable "app_network_cidr" {
  type    = string
  default = "10.100.0.0/16"
}


variable "app_db_network_cidr" {
  type    = string
  default = "10.110.0.0/16"
}


variable "ip_network_mgmt_secondary" {
  type    = string
  default = "10.128"
}

variable "app_network_secondary" {
  type    = string
  default = "10.200.0.0/16"
}

variable "app_db_network_secondary" {
  type    = string
  default = "10.210.0.0/16"
}
