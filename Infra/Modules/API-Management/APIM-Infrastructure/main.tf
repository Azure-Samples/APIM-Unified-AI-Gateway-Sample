# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# APIM Infrastructure Module
# ============================================================================
#
# This module contains only the APIM service creation
# Extracted from lines 35-61 of the original API-Management module
#
# ============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# API Management service with system-assigned managed identity
resource "azurerm_api_management" "apim" {
  name                = "${var.resource_prefix}-uaig-apimdev"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "sample"
  publisher_email     = var.publisher_email
  sku_name            = var.apim_sku_name
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    postcondition {
      condition     = self.identity[0].type == "SystemAssigned" && self.identity[0].principal_id != null
      error_message = "APIM system-assigned managed identity must be enabled and provisioned. This is required for authenticating to Azure OpenAI and Foundry backends using managed identity."
    }
  }
}