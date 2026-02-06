# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "id" {
  description = "Application Insights resource ID"
  value       = azurerm_application_insights.appinsights.id
}

output "name" {
  description = "Application Insights resource name"
  value       = azurerm_application_insights.appinsights.name
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "instrumentation_key_secret_id" {
  description = "Key Vault secret ID for Application Insights instrumentation key"
  value       = azurerm_key_vault_secret.appinsights_instrumentation_key.id
}

output "connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.appinsights_workspace.id
}