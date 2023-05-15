locals {

  staticwebapps = yamldecode(file("${path.module}/staticwebapp.yaml"))

  staticwebapp = { for v in flatten([for stat_name, stat_value in local.staticwebapps :
    {
      stat_name  = stat_name
      stat_value = stat_value
    }
  ]) : v.stat_name => v }
}

resource "azurerm_static_site" "example" {
  for_each = local.staticwebapp

  name                = each.value.stat_value.name
  location            = var.common.location
  resource_group_name = var.common.resource_group_name

  sku_tier = each.value.stat_value.sku_tier
  sku_size = each.value.stat_value.sku_size
  identity {
    type = each.value.stat_value.identity_type
  }
}