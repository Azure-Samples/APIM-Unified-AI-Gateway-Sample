# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# App Insights Configuration Module
# ============================================================================
#
# This module contains KQL queries deployment
# Extracted from the original App-Insights module
#
# ============================================================================
# No data sources needed - using resource ID passed as variable

# ============================================================================
# KQL Queries - Deployed as Application Insights Analytics Items
# ============================================================================

# Analytics Query (authentication and backend usage)
resource "azurerm_application_insights_analytics_item" "analytics" {
  name                    = "Analytics"
  application_insights_id = var.app_insights_id
  content                 = file("${path.module}/../../../Resources/Queries/general-analytics.kql")
  scope                   = "shared"
  type                    = "query"
}

# Token Usage Analysis Query
resource "azurerm_application_insights_analytics_item" "token_usage" {
  name                    = "Token Usage Analysis"
  application_insights_id = var.app_insights_id
  content                 = file("${path.module}/../../../Resources/Queries/token-usage.kql")
  scope                   = "shared"
  type                    = "query"
}