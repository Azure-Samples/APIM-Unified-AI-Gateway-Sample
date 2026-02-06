# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "name" {
  description = "API Management service name"
  value       = azurerm_api_management.apim.name
}

output "id" {
  description = "API Management service resource ID"
  value       = azurerm_api_management.apim.id
}

output "gateway_url" {
  description = "API Management gateway URL"
  value       = azurerm_api_management.apim.gateway_url
}

output "principal_id" {
  description = "API Management system-assigned managed identity principal ID"
  value       = azurerm_api_management.apim.identity[0].principal_id
}