# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "apim_gateway_url" {
  description = "Gateway URL of the Azure API Management instance"
  value       = local.apim.gateway_url
}

output "apim_name" {
  description = "Name of the Azure API Management instance"
  value       = local.apim.name
}

output "apim_resource_id" {
  description = "Full Azure resource ID of the API Management instance"
  value       = local.apim.id
}

output "apim_subscription_key_kv_ref" {
  description = "Key Vault reference for APIM subscription key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.apim_configuration.apim_subscription_key_secret_name}"
}

output "entra_app_client_secret_kv_ref" {
  description = "Key Vault reference for Entra App client secret (AZD secrets format)"
  value       = var.entra_app_client_secret_kv_ref != "" ? var.entra_app_client_secret_kv_ref : "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.entra_id[0].entra_app_client_secret_name}"
}

output "entra_app_id" {
  description = "Entra ID App Registration Client ID"
  value       = local.entra_app_id
}

output "entra_app_identifier_uri" {
  description = "Entra ID App Registration Identifier URI"
  value       = local.entra_app_identifier_uri
}

output "foundry_inference_endpoint" {
  description = "Foundry inference tier endpoint for APIM backend configuration"
  value       = module.foundry_inference.foundry_account_endpoint
}

output "foundry_inference_key_kv_ref" {
  description = "Key Vault reference for Foundry inference tier key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_inference.key_vault_secret_name}"
}

output "foundry_premium_endpoints" {
  description = "Foundry premium tier endpoints array (3 regions)"
  value = [
    module.foundry_premium_region_1.foundry_account_endpoint,
    module.foundry_premium_region_2.foundry_account_endpoint,
    module.foundry_premium_region_3.foundry_account_endpoint
  ]
}

output "foundry_premium_region1_key_kv_ref" {
  description = "Key Vault reference for Foundry premium tier Region 1 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_premium_region_1.key_vault_secret_name}"
}

output "foundry_premium_region2_key_kv_ref" {
  description = "Key Vault reference for Foundry premium tier Region 2 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_premium_region_2.key_vault_secret_name}"
}

output "foundry_premium_region3_key_kv_ref" {
  description = "Key Vault reference for Foundry premium tier Region 3 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_premium_region_3.key_vault_secret_name}"
}

output "foundry_standard_endpoints" {
  description = "Foundry standard tier endpoints array (3 regions)"
  value = [
    module.foundry_standard_region_1.foundry_account_endpoint,
    module.foundry_standard_region_2.foundry_account_endpoint,
    module.foundry_standard_region_3.foundry_account_endpoint
  ]
}

output "foundry_standard_region1_key_kv_ref" {
  description = "Key Vault reference for Foundry standard tier Region 1 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_standard_region_1.key_vault_secret_name}"
}

output "foundry_standard_region2_key_kv_ref" {
  description = "Key Vault reference for Foundry standard tier Region 2 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_standard_region_2.key_vault_secret_name}"
}

output "foundry_standard_region3_key_kv_ref" {
  description = "Key Vault reference for Foundry standard tier Region 3 key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${module.foundry_standard_region_3.key_vault_secret_name}"
}

output "gemini_endpoint" {
  description = "Gemini API endpoint URL"
  value       = var.gemini_endpoint != "" ? var.gemini_endpoint : "https://generativelanguage.googleapis.com"
}

output "gemini_secret_kv_ref" {
  description = "Key Vault reference for Gemini API key (AZD secrets format)"
  value       = "akvs://${data.azurerm_client_config.current.subscription_id}/${var.key_vault_name}/${local.gemini_secret_name}"
}

output "key_vault_name" {
  description = "Name of the Key Vault containing secrets"
  value       = var.key_vault_name
}

output "tenant_id" {
  description = "Entra ID Tenant ID for JWT authentication"
  value       = data.azurerm_client_config.current.tenant_id
}
