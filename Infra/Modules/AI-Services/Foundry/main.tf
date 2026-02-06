# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# Microsoft Foundry Module - General Purpose
# ============================================================================
# This module creates a Microsoft Foundry service/project.
#
# Each Foundry instance includes:
# - One or more model deployments
# - One project
# - Key Vault secret for access key
#
# Supports flexible model configurations for any region and model combination.
# ============================================================================

terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# Foundry Account (AIServices with allowProjectManagement)
# ============================================================================

# Support both Entra ID and API Key authentication for Cognitive Services account
resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "${var.resource_prefix}-uaig-${var.foundry_name_suffix}-foundry"
  parent_id                 = var.resource_group_id
  location                  = var.region
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Support both Entra ID and API Key authentication for Cognitive Services account
      disableLocalAuth = false

      # Specifies that this is a Microsoft Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = "${var.resource_prefix}-uaig-${var.foundry_name_suffix}-foundry"

      publicNetworkAccess = "Enabled"
    }
  }
}

# ============================================================================
# Model Deployment
# ============================================================================

resource "azapi_resource" "deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  name      = var.deployment_name
  parent_id = azapi_resource.ai_foundry.id
  depends_on = [
    azapi_resource.ai_foundry
  ]

  body = {
    sku = {
      name     = var.sku_name
      capacity = var.capacity
    }
    properties = {
      model = {
        format  = var.model_format
        name    = var.model_name
        version = var.model_version
      }
    }
  }
}

# ============================================================================
# Project
# ============================================================================

resource "azapi_resource" "ai_foundry_project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "${var.foundry_name_suffix}-project"
  parent_id                 = azapi_resource.ai_foundry.id
  location                  = var.region
  schema_validation_enabled = false

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      displayName = "${var.foundry_name_suffix} Project"
      description = "Foundry project for ${var.foundry_name_suffix}"
    }
  }
}

# ============================================================================
# Retrieve Access Keys
# ============================================================================

resource "azapi_resource_action" "ai_foundry_keys" {
  type                   = "Microsoft.CognitiveServices/accounts@2025-06-01"
  resource_id            = azapi_resource.ai_foundry.id
  action                 = "listKeys"
  response_export_values = ["key1", "key2"]

  depends_on = [
    azapi_resource.deployment,
    azapi_resource.ai_foundry_project
  ]
}

# ============================================================================
# Store Access Key in Key Vault
# ============================================================================

resource "azurerm_key_vault_secret" "foundry_key" {
  name         = "UAIG-FOUNDRY-${upper(replace(var.foundry_name_suffix, "-", "-"))}-KEY"
  value        = azapi_resource_action.ai_foundry_keys.output.key2
  key_vault_id = var.key_vault_id
}
