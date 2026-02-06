# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# Entra ID Module Outputs
# ============================================================================

output "entra_app_id" {
  description = "Entra ID App Registration Client ID"
  value       = azuread_application.gateway_app.client_id
}

output "entra_app_identifier_uri" {
  description = "Entra ID App Registration Identifier URI"
  value       = azuread_application_identifier_uri.gateway_app_uri.identifier_uri
  depends_on  = [azuread_application_identifier_uri.gateway_app_uri]
}

output "client_secret" {
  description = "Client secret for the Entra App Registration"
  value       = azuread_application_password.gateway_app_secret.value
  sensitive   = true
}

output "entra_app_client_secret_name" {
  description = "Name of the Key Vault secret containing the Entra App client secret"
  value       = azurerm_key_vault_secret.entra_client_secret.name
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "service_principal_object_id" {
  description = "Service Principal Object ID for RBAC assignments"
  value       = azuread_service_principal.gateway_sp.object_id
}