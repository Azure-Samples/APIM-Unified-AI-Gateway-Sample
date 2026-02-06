# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# Foundry Module Outputs
# ============================================================================

output "foundry_account_id" {
  description = "Resource ID of the Foundry account (for RBAC assignments)"
  value       = azapi_resource.ai_foundry.id
}

output "foundry_account_endpoint" {
  description = "Account endpoint for APIM backend configuration (format: https://{name}.services.ai.azure.com/)"
  value       = azapi_resource.ai_foundry.output.properties.endpoint
}

output "key_vault_secret_name" {
  description = "Name of the Key Vault secret containing the access key"
  value       = azurerm_key_vault_secret.foundry_key.name
}
