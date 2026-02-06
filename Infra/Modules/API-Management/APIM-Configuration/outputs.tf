# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "apim_subscription_key" {
  description = "APIM subscription key for API access"
  value       = azurerm_api_management_subscription.unified_ai_subscription.primary_key
  sensitive   = true
}

output "apim_subscription_key_secret_name" {
  description = "Key Vault secret name for APIM subscription key"
  value       = azurerm_key_vault_secret.apim_subscription_key.name
}

output "apim_id" {
  description = "APIM resource ID"
  value       = var.apim_id
}

output "apim_name" {
  description = "APIM name extracted from resource ID"
  value       = local.apim_name
}

output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = var.apim_gateway_url
}