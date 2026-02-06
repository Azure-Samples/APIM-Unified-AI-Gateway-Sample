# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ============================================================================
# Unified AI Gateway Infrastructure
# ============================================================================
# This file orchestrates all infrastructure modules for the Unified AI Gateway.
# All resources have been organized into reusable modules under ./Modules/
#
# DEPLOYMENT TIMING EXPECTATIONS:
# - Resource Group & App Registration: 1-2 minutes
# - Application Insights & Log Analytics: 2-5 minutes
# - OpenAI Cognitive Accounts (3 regions): 2-15 minutes each
# - AI Services (Phi-4): 10-20 minutes
# - API Management Service: 5-45 minutes depending on SKU
# - Policy Configuration & Role Assignments: 5-10 minutes
# - Total deployment time: 15-20 minutes
#
# ============================================================================

# ============================================================================
# Data Sources
# ============================================================================

# Get current Azure authentication context (tenant_id, subscription_id, client_id, object_id)
data "azurerm_client_config" "current" {}

# ============================================================================
# Key Vault Reference (for APIM Named Value integration)
# ============================================================================

# Reference to the Key Vault containing secrets
data "azurerm_key_vault" "secrets" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

# Conditional data sources for existing resources
data "azurerm_api_management" "existing" {
  count               = var.existing_apim_name != "" ? 1 : 0
  name                = var.existing_apim_name
  resource_group_name = var.existing_apim_rg

  lifecycle {
    postcondition {
      condition     = length(self.identity) > 0
      error_message = <<-EOT
        ERROR: Existing APIM '${var.existing_apim_name}' must have System-Assigned Managed Identity enabled to access Key Vault secrets.
        
        Enable in Portal: API Management > ${var.existing_apim_name} > Security > Managed identities > System assigned > Status: On
        
        For more information: https://aka.ms/apimmsi
      EOT
    }
  }
}

data "azurerm_application_insights" "existing" {
  count               = var.existing_appinsight_name != "" ? 1 : 0
  name                = var.existing_appinsight_name
  resource_group_name = var.existing_appinsight_rg
}

data "azuread_application" "existing" {
  count     = var.existing_entra_app_id != "" ? 1 : 0
  client_id = var.existing_entra_app_id
}

data "azuread_service_principal" "existing" {
  count     = var.existing_entra_app_id != "" ? 1 : 0
  client_id = var.existing_entra_app_id
}

# ============================================================================
# Resource Group
# ============================================================================

module "foundation" {
  source = "./Modules/Resource-Group"

  resource_group_name = var.resource_group_name
  location            = var.location
  environment_name    = var.environment_name
  resource_prefix     = local.resource_prefix
  tags                = local.tags
}

# ============================================================================
# Conditional App Insights Infrastructure (only when creating new)
# ============================================================================

module "app_insights_infrastructure" {
  count  = var.existing_appinsight_name == "" ? 1 : 0
  source = "./Modules/App-Insights/AI-Infrastructure"

  resource_group_name = local.apim_resource_group_name
  location            = local.apim_location
  resource_prefix     = local.resource_prefix
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id
}

# ============================================================================
# AI Services
# ============================================================================

# Inference Tier Foundry
module "foundry_inference" {
  source = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_inference_region
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "inference"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "Phi-4"
  model_name      = "Phi-4"
  model_format    = "Microsoft"
  model_version   = "7"
  sku_name        = "GlobalStandard"
  capacity        = 1
}

# Premium Tier Region 1 Foundry
module "foundry_premium_region_1" {
  depends_on = [module.foundry_inference]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_premium_region_1
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "premium-region1"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1"
  model_name      = "gpt-4.1"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 1
}

# Premium Tier Region 2 Foundry
module "foundry_premium_region_2" {
  depends_on = [module.foundry_premium_region_1]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_premium_region_2
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "premium-region2"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1"
  model_name      = "gpt-4.1"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 1
}

# Premium Tier Region 3 Foundry
module "foundry_premium_region_3" {
  depends_on = [module.foundry_premium_region_2]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_premium_region_3
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "premium-region3"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1"
  model_name      = "gpt-4.1"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 1
}

# Standard Tier Region 1 Foundry
module "foundry_standard_region_1" {
  depends_on = [module.foundry_premium_region_3]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_standard_region_1
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "standard-region1"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1-mini"
  model_name      = "gpt-4.1-mini"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 2
}

# Standard Tier Region 2 Foundry
module "foundry_standard_region_2" {
  depends_on = [module.foundry_standard_region_1]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_standard_region_2
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "standard-region2"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1-mini"
  model_name      = "gpt-4.1-mini"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 2
}

# Standard Tier Region 3 Foundry
module "foundry_standard_region_3" {
  depends_on = [module.foundry_standard_region_2]
  source     = "./Modules/AI-Services/Foundry"

  resource_group_id   = module.foundation.resource_group_id
  region              = var.foundry_standard_region_3
  resource_prefix     = local.resource_prefix
  foundry_name_suffix = "standard-region3"
  tags                = local.tags
  key_vault_id        = data.azurerm_key_vault.secrets.id

  deployment_name = "gpt-4.1-mini"
  model_name      = "gpt-4.1-mini"
  model_version   = "2025-04-14"
  sku_name        = "Standard"
  capacity        = 2
}

# ============================================================================
# Security
# ============================================================================

module "entra_id" {
  count  = var.existing_entra_app_id == "" ? 1 : 0
  source = "./Modules/Security/Entra-Id"

  naming_prefix = local.resource_prefix
  key_vault_id  = data.azurerm_key_vault.secrets.id
  tags          = local.tags
}

# ============================================================================
# Conditional APIM Infrastructure (only when creating new)
# ============================================================================

module "apim_infrastructure" {
  count  = var.existing_apim_name == "" ? 1 : 0
  source = "./Modules/API-Management/APIM-Infrastructure"

  resource_group_name = module.foundation.resource_group_name
  location            = var.location
  resource_prefix     = local.resource_prefix
  publisher_email     = var.publisher_email != "" ? var.publisher_email : "admin@example.com"
  apim_sku_name       = var.apim_sku_name != "" ? var.apim_sku_name : "BasicV2_1"
  tags                = local.tags
}

# ============================================================================
# App Insights Configuration
# ============================================================================

module "app_insights_configuration" {
  source = "./Modules/App-Insights/AI-Configuration"

  tags            = local.tags
  app_insights_id = local.app_insights.id
}

# ============================================================================
# APIM Configuration
# ============================================================================

module "apim_configuration" {
  depends_on = [azurerm_role_assignment.apim_key_vault_secrets_user]
  source     = "./Modules/API-Management/APIM-Configuration"

  tags             = local.tags
  apim_id          = local.apim.id
  apim_gateway_url = local.apim.gateway_url

  app_insights_id                            = local.app_insights.id
  app_insights_instrumentation_key           = local.app_insights.instrumentation_key
  app_insights_instrumentation_key_secret_id = var.existing_appinsight_name == "" ? module.app_insights_infrastructure[0].instrumentation_key_secret_id : null
  use_key_vault_for_appinsights              = var.existing_appinsight_name == ""

  # App Insights logger linking (inferred: create new logger if existing_logger_name is empty)
  create_appinsights_logger = var.existing_logger_name == ""
  existing_logger_name      = var.existing_logger_name

  tenant_id    = data.azurerm_client_config.current.tenant_id
  entra_app_id = local.entra_app_id

  foundry_inference_endpoint = module.foundry_inference.foundry_account_endpoint

  foundry_premium_endpoints = [
    module.foundry_premium_region_1.foundry_account_endpoint,
    module.foundry_premium_region_2.foundry_account_endpoint,
    module.foundry_premium_region_3.foundry_account_endpoint
  ]
  foundry_standard_endpoints = [
    module.foundry_standard_region_1.foundry_account_endpoint,
    module.foundry_standard_region_2.foundry_account_endpoint,
    module.foundry_standard_region_3.foundry_account_endpoint
  ]

  gemini_key_vault_secret_id = "${data.azurerm_key_vault.secrets.vault_uri}secrets/${local.gemini_secret_name}"
  gemini_endpoint            = var.gemini_endpoint

  key_vault_id = data.azurerm_key_vault.secrets.id
}

# ============================================================================
# RBAC Security
# ============================================================================

# Grant APIM Managed Identity access to Key Vault secrets
resource "azurerm_role_assignment" "apim_key_vault_secrets_user" {
  count                = var.existing_apim_name != "" ? (local.apim_principal_id != null ? 1 : 0) : 1
  scope                = data.azurerm_key_vault.secrets.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.apim_principal_id
}

module "rbac" {
  count  = var.existing_apim_name != "" ? (local.apim_principal_id != null ? 1 : 0) : 1
  source = "./Modules/Security/RBAC"

  apim_principal_id           = local.apim_principal_id
  service_principal_object_id = local.service_principal_object_id

  foundry_account_ids = [
    module.foundry_inference.foundry_account_id,
    module.foundry_premium_region_1.foundry_account_id,
    module.foundry_premium_region_2.foundry_account_id,
    module.foundry_premium_region_3.foundry_account_id,
    module.foundry_standard_region_1.foundry_account_id,
    module.foundry_standard_region_2.foundry_account_id,
    module.foundry_standard_region_3.foundry_account_id
  ]

  apim_id = local.apim.id
  tags    = local.tags
}

