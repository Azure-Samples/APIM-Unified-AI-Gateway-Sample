# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ============================================================================
# Local Values
# ============================================================================
# Computed values and resource selectors for the Unified AI Gateway infrastructure.
# ============================================================================

locals {
  # Custom tags and naming (computed from environment, location, and subscription)
  tags            = { azd-env-name : var.environment_name }
  sha             = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_prefix = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)

  # Extract secret name from akvs:// reference (akvs://sub-id/vault/secret-name -> secret-name)
  gemini_secret_name = can(regex("^akvs://", var.gemini_secret_kv_ref)) ? split("/", var.gemini_secret_kv_ref)[4] : var.gemini_secret_kv_ref
}

# Resource selectors (automatically determines existing OR new resources)
locals {
  # Determine which resource group APIM is in (existing or new)
  apim_resource_group_name = var.existing_apim_name != "" ? var.existing_apim_rg : module.foundation.resource_group_name

  # Use APIM's location for App Insights to keep them co-located
  apim_location = var.existing_apim_name != "" ? data.azurerm_api_management.existing[0].location : var.location

  # Select APIM resource (existing or newly created)
  apim = var.existing_apim_name != "" ? data.azurerm_api_management.existing[0] : module.apim_infrastructure[0]

  # Select App Insights resource (existing or newly created)
  app_insights = var.existing_appinsight_name != "" ? data.azurerm_application_insights.existing[0] : module.app_insights_infrastructure[0]

  # Select Entra ID app registration (existing or newly created)
  entra_app_id                = var.existing_entra_app_id != "" ? var.existing_entra_app_id : module.entra_id[0].entra_app_id
  entra_app_identifier_uri    = var.existing_entra_app_id != "" ? "api://${var.existing_entra_app_id}" : module.entra_id[0].entra_app_identifier_uri
  service_principal_object_id = var.existing_entra_app_id != "" ? data.azuread_service_principal.existing[0].object_id : module.entra_id[0].service_principal_object_id

  # APIM principal ID (data source has identity block, module outputs principal_id directly)
  apim_principal_id = var.existing_apim_name != "" ? (
    length(data.azurerm_api_management.existing[0].identity) > 0
    ? data.azurerm_api_management.existing[0].identity[0].principal_id
    : null
  ) : module.apim_infrastructure[0].principal_id
}
