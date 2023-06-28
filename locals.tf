locals {
  tags = merge(var.regional_tags, var.global_tags, {
    Function = "Networking"
  })
}
