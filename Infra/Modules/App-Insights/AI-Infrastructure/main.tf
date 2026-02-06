# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# App Insights Infrastructure Module
# ============================================================================
#
# This module contains only the App Insights instance creation
# Extracted from the original App-Insights module
#
# ============================================================================

# Log Analytics Workspace for Application Insights
# Creating explicitly to ensure it's in the same resource group as other resources
resource "azurerm_log_analytics_workspace" "appinsights_workspace" {
  name                = "${var.resource_prefix}-uaig-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights for monitoring and telemetry
# Now explicitly references the Log Analytics workspace to ensure same resource group
resource "azurerm_application_insights" "appinsights" {
  name                = "${var.resource_prefix}-uaig-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.appinsights_workspace.id
  tags                = var.tags
}

# Store instrumentation key in Key Vault
resource "azurerm_key_vault_secret" "appinsights_instrumentation_key" {
  name         = "APPINSIGHTS-INSTRUMENTATION-KEY"
  value        = azurerm_application_insights.appinsights.instrumentation_key
  key_vault_id = var.key_vault_id
}