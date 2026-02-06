# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Conditional resource group creation
data "azurerm_resource_group" "existing" {
  count = var.resource_group_name != "" ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  name     = "${var.environment_name}-${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name     = var.resource_group_name != "" ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.rg[0].name
  resource_group_location = var.resource_group_name != "" ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.rg[0].location
  resource_group_id       = var.resource_group_name != "" ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg[0].id
}