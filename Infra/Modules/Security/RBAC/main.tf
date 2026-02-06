# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# RBAC Role Assignments Module
# ============================================================================

# ============================================================================
# Role Assignments for Unified AI Gateway
# ============================================================================

# Cognitive Services User role for Foundry access via APIM Managed Identity
resource "azurerm_role_assignment" "foundry_user_apim" {
  count                = length(var.foundry_account_ids)
  scope                = var.foundry_account_ids[count.index]
  role_definition_name = "Cognitive Services User"
  principal_id         = var.apim_principal_id
  principal_type       = "ServicePrincipal"
}

# API Management Service Contributor role for APIM access
resource "azurerm_role_assignment" "apim_contributor" {
  scope                = var.apim_id
  role_definition_name = "API Management Service Contributor"
  principal_id         = var.service_principal_object_id
}