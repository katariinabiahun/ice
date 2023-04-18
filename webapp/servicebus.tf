locals {

  srv_bus = yamldecode(file("${path.module}/servicebus.yaml"))

  srvbus_queue = { for k, v in flatten([for srvbus_name, srvbus_value in local.srv_bus :
    [for namespace_name, namespace_value in try(srvbus_value.namespace, {}) :
      [for queue_name, queue_value in try(srvbus_value.queue, {}) :
        [for auth_rule_name, auth_rule_value in try(srvbus_value.auth_rule, {}) :
          {
            srvbus_name     = srvbus_name
            srvbus_value    = srvbus_value
            namespace_name  = namespace_name
            namespace_value = namespace_value
            queue_name      = queue_name
            queue_value     = queue_value
            auth_rule_name  = auth_rule_name
            auth_rule_value = auth_rule_value
          }
        ]
      ]
    ]
  ]) : join("-", [v.srvbus_name, v.namespace_name, v.queue_name, v.auth_rule_name]) => v }
}

resource "azurerm_servicebus_namespace" "example" {
  for_each = local.srvbus_queue

  name                = each.value.namespace_name
  location            = var.common.location
  resource_group_name = var.common.resource_group_name
  sku                 = each.value.namespace_value.sku

  tags = {
    source = "terraform"
  }
}

resource "azurerm_servicebus_queue" "example" {
  for_each = local.srvbus_queue

  name         = each.value.queue_name
  namespace_id = azurerm_servicebus_namespace.example[keys(local.srvbus_queue)[0]].id

  enable_partitioning = each.value.queue_value.enable_partitioning
}

resource "azurerm_servicebus_queue_authorization_rule" "example" {
  for_each = local.srvbus_queue

  name     = each.value.auth_rule_name
  queue_id = azurerm_servicebus_queue.example[keys(local.srvbus_queue)[0]].id

  listen = each.value.auth_rule_value.listen
  send   = each.value.auth_rule_value.send
  manage = each.value.auth_rule_value.manage
}
