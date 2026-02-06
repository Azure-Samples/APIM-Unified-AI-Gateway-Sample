# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# APIM Configuration Module
# ============================================================================
#
# This module contains all APIM configuration resources
#
# ============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.7.0"
    }
  }
}

# ============================================================================
# Local Variables
# ============================================================================
# Extract APIM name and resource group from the resource ID

locals {
  # Parse APIM resource ID to extract name and resource group
  apim_resource_group = regex("resourceGroups/([^/]+)", var.apim_id)[0]
  apim_name           = regex("service/([^/]+)", var.apim_id)[0]

  # Parse App Insights resource ID to extract name and resource group
  app_insights_resource_group = regex("resourceGroups/([^/]+)", var.app_insights_id)[0]
  app_insights_name           = regex("components/([^/]+)", var.app_insights_id)[0]
}

# ============================================================================
# Data Sources
# ============================================================================
# Verify APIM is fully ready before attempting configuration
# This addresses timing issues where provisioningState is "Succeeded" but
# the management API is not yet ready to accept configuration requests

data "azurerm_api_management" "apim_readiness_check" {
  name                = local.apim_name
  resource_group_name = local.apim_resource_group

  lifecycle {
    postcondition {
      condition     = self.gateway_url != null && self.gateway_url != ""
      error_message = "APIM management API is not ready yet. Gateway URL is null or empty, indicating the service is still initializing."
    }
  }
}

# Additional delay to ensure APIM management API is fully operational
# Even after gateway_url is available, the management API may need extra time
resource "time_sleep" "apim_management_api_delay" {
  depends_on = [data.azurerm_api_management.apim_readiness_check]

  create_duration = "60s"
}

# ============================================================================
# APIM Identity Configuration
# ============================================================================
# APIM-Infrastructure module creates new APIM instances with system-assigned
# managed identity enabled. This identity can be used for additional scenarios
# like Key Vault access or other Azure service integrations if needed in the future.
#
# Note: This configuration module does not have a direct dependency on APIM's
# managed identity. RBAC role assignments use the Entra ID service principal
# (from the Entra-Id module), not APIM's managed identity.

data "azurerm_client_config" "current" {}

# ============================================================================
# APIM Logger Configuration
# ============================================================================
# Conditionally create Application Insights logger based on variable.
# Set create_appinsights_logger=false when APIM already has logger configured.

# Link Application Insights to API Management
# Uses Key Vault reference for instrumentation key when available (APIM pulls from Key Vault using managed identity)
# Falls back to direct key for existing App Insights resources
resource "azurerm_api_management_logger" "appinsights_logger" {
  count               = var.create_appinsights_logger ? 1 : 0
  name                = "appinsights-logger"
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.use_key_vault_for_appinsights ? "{{${azurerm_api_management_named_value.appinsights_key_vault_ref[0].name}}}" : var.app_insights_instrumentation_key
  }

  depends_on = [
    azurerm_api_management_named_value.appinsights_key_vault_ref
  ]
}

# Named Value that references Key Vault secret for instrumentation key
# Only created when Key Vault secret ID is provided (for new App Insights)
resource "azurerm_api_management_named_value" "appinsights_key_vault_ref" {
  count               = var.create_appinsights_logger && var.use_key_vault_for_appinsights ? 1 : 0
  name                = "AppInsights-InstrumentationKey"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "AppInsights-InstrumentationKey"
  secret              = true

  value_from_key_vault {
    secret_id = var.app_insights_instrumentation_key_secret_id
  }
}

# Data source to reference existing logger when not creating a new one
data "azapi_resource" "existing_logger" {
  count     = var.create_appinsights_logger ? 0 : 1
  type      = "Microsoft.ApiManagement/service/loggers@2023-05-01-preview"
  name      = var.existing_logger_name
  parent_id = var.apim_id
}

# Local to get the logger ID (either newly created or existing)
locals {
  logger_id = var.create_appinsights_logger ? azurerm_api_management_logger.appinsights_logger[0].id : data.azapi_resource.existing_logger[0].id
}

# ============================================================================
# Named Values for Configuration Management
# ============================================================================

# Gemini API Key (retrieved from Key Vault by APIM managed identity)
resource "azurerm_api_management_named_value" "gemini_api_key" {
  name                = "Gemini-ApiKey"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "Gemini-ApiKey"
  secret              = true

  value_from_key_vault {
    secret_id = var.gemini_key_vault_secret_id
  }

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# JWT Authentication Configuration Named Values
resource "azurerm_api_management_named_value" "jwt_tenant_id" {
  name                = "JWT-TenantId"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "JWT-TenantId"
  value               = var.tenant_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_named_value" "jwt_app_registration_id" {
  name                = "JWT-AppRegistrationId"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "JWT-AppRegistrationId"
  value               = var.entra_app_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_named_value" "jwt_issuer" {
  name                = "JWT-Issuer"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "JWT-Issuer"
  value               = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_named_value" "jwt_openid_config_url" {
  name                = "JWT-OpenIdConfigUrl"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "JWT-OpenIdConfigUrl"
  value               = "https://login.microsoftonline.com/${var.tenant_id}/v2.0/.well-known/openid-configuration"

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Subscription key for gateway authentication - references Key Vault
resource "azurerm_api_management_named_value" "unified_ai_gateway_sub_key" {
  name                = "UnifiedAIGatewaySubKey"
  resource_group_name = local.apim_resource_group
  api_management_name = local.apim_name
  display_name        = "UnifiedAIGatewaySubKey"
  secret              = true

  value_from_key_vault {
    secret_id = azurerm_key_vault_secret.apim_subscription_key.id
  }

  depends_on = [azurerm_key_vault_secret.apim_subscription_key]
}

# ============================================================================
# External Backend - Gemini
# ============================================================================

# Gemini external backend (no circuit breaker)
resource "azapi_resource" "gemini_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "gemini-backend"
  parent_id = var.apim_id

  schema_validation_enabled = true

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_named_value.gemini_api_key
  ]

  body = {
    properties = {
      type     = "Single"
      url      = "${trimsuffix(var.gemini_endpoint != "" ? var.gemini_endpoint : "https://generativelanguage.googleapis.com", "/")}/"
      protocol = "http"
      credentials = {
        query  = {}
        header = {}
      }
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
}

# OpenAI Responses API Backend - dedicated backend for responses API
resource "azapi_resource" "aoai_standard_responses" {
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "standard-responses-backend"
  parent_id = var.apim_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]

  body = {
    properties = {
      type     = "Single"
      url      = var.foundry_standard_endpoints[0]
      protocol = "http"
      circuitBreaker = {
        rules = [
          {
            name         = "StandardRule"
            tripDuration = "PT1M"
            failureCondition = {
              count    = 50
              interval = "PT1M"
              statusCodeRanges = [
                {
                  min = 429
                  max = 429
                },
                {
                  min = 500
                  max = 503
                }
              ]
            }
            acceptRetryAfter = true
          }
        ]
      }
    }
  }

  schema_validation_enabled = true
}

# ============================================================================
# AI Services Backend Configurations
# ============================================================================

# AI Services (Inference Tier) Backend Configuration
resource "azapi_resource" "inference_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "inference-backend"
  parent_id = var.apim_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]

  body = {
    properties = {
      type     = "Single"
      url      = var.foundry_inference_endpoint
      protocol = "http"
    }
  }

  schema_validation_enabled = true
}

# ============================================================================
# OpenAI Backend Configurations - Premium Pool (GPT-4o)
# ============================================================================

# Premium Pool Backend - Advanced Load Balancing with Circuit Breakers
resource "azapi_resource" "premium_pool_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "premium-pool"
  parent_id = var.apim_id

  body = {
    properties = {
      type = "Pool"
      pool = {
        services = [
          for i in range(length(var.foundry_premium_endpoints)) : {
            id       = "${var.apim_id}/backends/premium-service-${i + 1}"
            priority = 1
            weight   = 1
          }
        ]
      }
    }
  }

  schema_validation_enabled = true
  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azapi_resource.openai_premium_backends
  ]
}

# Individual premium tier service backends (count-based for arrays)
resource "azapi_resource" "openai_premium_backends" {
  count     = length(var.foundry_premium_endpoints)
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "premium-service-${count.index + 1}"
  parent_id = var.apim_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]

  body = {
    properties = {
      type     = "Single"
      url      = var.foundry_premium_endpoints[count.index]
      protocol = "http"
      circuitBreaker = {
        rules = [
          {
            name         = "StandardRule"
            tripDuration = "PT1M"
            failureCondition = {
              count    = 3
              interval = "PT1M"
              statusCodeRanges = [
                {
                  min = 429
                  max = 429
                },
                {
                  min = 500
                  max = 503
                }
              ]
            }
            acceptRetryAfter = true
          }
        ]
      }
    }
  }

  schema_validation_enabled = true
}

# ============================================================================
# OpenAI Backend Configurations - Standard Pool
# ============================================================================

# Standard Pool Backend - Basic Load Balancing
resource "azapi_resource" "standard_pool_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "standard-pool"
  parent_id = var.apim_id

  body = {
    properties = {
      type = "Pool"
      pool = {
        services = [
          for i in range(length(var.foundry_standard_endpoints)) : {
            id       = "${var.apim_id}/backends/standard-service-${i + 1}"
            priority = 1
            weight   = 1
          }
        ]
      }
    }
  }

  schema_validation_enabled = true
  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azapi_resource.openai_standard_backends
  ]
}

# Individual standard tier service backends
resource "azapi_resource" "openai_standard_backends" {
  count     = length(var.foundry_standard_endpoints)
  type      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name      = "standard-service-${count.index + 1}"
  parent_id = var.apim_id

  depends_on = [data.azurerm_api_management.apim_readiness_check]

  body = {
    properties = {
      type     = "Single"
      url      = var.foundry_standard_endpoints[count.index]
      protocol = "http"
      circuitBreaker = {
        rules = [
          {
            name         = "StandardRule"
            tripDuration = "PT1M"
            failureCondition = {
              count    = 3
              interval = "PT1M"
              statusCodeRanges = [
                {
                  min = 429
                  max = 429
                },
                {
                  min = 500
                  max = 503
                }
              ]
            }
            acceptRetryAfter = true
          }
        ]
      }
    }
  }

  schema_validation_enabled = true
}

# ============================================================================
# API Configuration
# ============================================================================

# Placeholder API (wildcard) - real backend policies added later
resource "azurerm_api_management_api" "wildcard" {
  name                  = "gateway-wildcard"
  resource_group_name   = local.apim_resource_group
  api_management_name   = local.apim_name
  revision              = "1"
  display_name          = "Unified AI Gateway Wildcard"
  path                  = "unified-ai"
  protocols             = ["https"]
  subscription_required = true

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/../../../Resources/Schema/unifiedaigateway-wildcard-api.json")
  }

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Application Insights diagnostic configuration for the API
# Configure minimal diagnostics with always_log_errors and custom metrics enabled
# Uses azapi_resource to support the metrics property (custom metrics for emit-metric policy)
resource "azapi_resource" "wildcard_appinsights" {
  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = azurerm_api_management_api.wildcard.id

  depends_on = [
    data.azurerm_api_management.apim_readiness_check
  ]

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "Legacy"
      verbosity               = "information"
      logClientIp             = true
      loggerId                = local.logger_id
      metrics                 = true
      sampling = {
        samplingType = "fixed"
        percentage   = 100.0
      }
      frontend = {
        request = {
          headers = []
          body = {
            bytes = 0
          }
        }
        response = {
          headers = []
          body = {
            bytes = 0
          }
        }
      }
      backend = {
        request = {
          headers = []
          body = {
            bytes = 0
          }
        }
        response = {
          headers = []
          body = {
            bytes = 0
          }
        }
      }
    }
  }
}

# ============================================================================
# Service-Level Application Insights Diagnostic
# ============================================================================
# This service-level diagnostic enables the Application Insights toggle in the Portal
# at the "All APIs" level, which is what controls the checkbox visibility
# Only create if we're also creating a new logger (same condition)
resource "azapi_resource" "service_appinsights_diagnostic" {
  count     = var.create_appinsights_logger ? 1 : 0
  type      = "Microsoft.ApiManagement/service/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = var.apim_id

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_logger.appinsights_logger
  ]

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "Legacy"
      verbosity               = "information"
      logClientIp             = true
      loggerId                = local.logger_id
      metrics                 = true
      sampling = {
        samplingType = "fixed"
        percentage   = 100.0
      }
      frontend = {
        request = {
          headers = []
          body = {
            bytes = 0
          }
        }
        response = {
          headers = []
          body = {
            bytes = 0
          }
        }
      }
      backend = {
        request = {
          headers = []
          body = {
            bytes = 0
          }
        }
        response = {
          headers = []
          body = {
            bytes = 0
          }
        }
      }
    }
  }
}

# ============================================================================
# Policy Fragments for Modular Policy Management
# ============================================================================

resource "azurerm_api_management_policy_fragment" "backend_selector" {
  name              = "backend-selector"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/backend-selector.xml")

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_named_value.gemini_api_key
  ]
}

resource "azurerm_api_management_policy_fragment" "config_cache" {
  name              = "central-cache-manager"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/central-cache-manager.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_policy_fragment" "debug_headers" {
  name              = "diagnostic-headers"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/diagnostic-headers.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_policy_fragment" "metadata_config" {
  name              = "metadata-config"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/metadata-config.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_policy_fragment" "path_builder" {
  name              = "path-builder"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/path-builder.xml")

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_named_value.gemini_api_key
  ]
}

resource "azurerm_api_management_policy_fragment" "token_limiter" {
  name              = "token-limiter"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/token-limiter.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_policy_fragment" "request_processor" {
  name              = "request-processor"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/request-processor.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_policy_fragment" "security_handler" {
  name              = "security-handler"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/security-handler.xml")

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_named_value.jwt_app_registration_id,
    azurerm_api_management_named_value.jwt_issuer,
    azurerm_api_management_named_value.jwt_openid_config_url
  ]
}

resource "azurerm_api_management_policy_fragment" "token_logger" {
  name              = "token-logger"
  api_management_id = var.apim_id
  format            = "rawxml"
  value             = file("${path.module}/../../../Resources/Fragments/token-logger.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# ============================================================================
# API Policy Configuration
# ============================================================================

# API Policy - applies the comprehensive unified policy to the wildcard API
resource "azurerm_api_management_api_policy" "wildcard_policy" {
  api_name            = azurerm_api_management_api.wildcard.name
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group
  xml_content         = file("${path.module}/../../../Resources/Policies/APIPolicies/unifiedaigateway-wildcard-api.xml")

  depends_on = [
    data.azurerm_api_management.apim_readiness_check,
    azurerm_api_management_policy_fragment.backend_selector,
    azurerm_api_management_policy_fragment.config_cache,
    azurerm_api_management_policy_fragment.debug_headers,
    azurerm_api_management_policy_fragment.metadata_config,
    azurerm_api_management_policy_fragment.path_builder,
    azurerm_api_management_policy_fragment.token_limiter,
    azurerm_api_management_policy_fragment.request_processor,
    azurerm_api_management_policy_fragment.security_handler,
    azurerm_api_management_policy_fragment.token_logger
  ]
}

# ============================================================================
# Products and Subscriptions
# ============================================================================

# JWT-based product (no subscription required)
resource "azurerm_api_management_product" "jwt" {
  product_id            = "unifiedaigateway-product-jwt"
  api_management_name   = local.apim_name
  resource_group_name   = local.apim_resource_group
  display_name          = "Unified AI Gateway JWT"
  description           = "Unified AI Gateway JWT"
  subscription_required = false
  approval_required     = false
  published             = false

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Subscription-based product (subscription required)
resource "azurerm_api_management_product" "subscription" {
  product_id            = "unifiedaigateway-product-subscription"
  api_management_name   = local.apim_name
  resource_group_name   = local.apim_resource_group
  display_name          = "Unified AI Gateway Subscription"
  description           = "Unified AI Gateway Subscription"
  subscription_required = true
  approval_required     = false
  published             = false

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Associate API to both products
resource "azurerm_api_management_product_api" "jwt_wildcard" {
  product_id          = azurerm_api_management_product.jwt.product_id
  api_name            = azurerm_api_management_api.wildcard.name
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_product_api" "subscription_wildcard" {
  product_id          = azurerm_api_management_product.subscription.product_id
  api_name            = azurerm_api_management_api.wildcard.name
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Product Policies
resource "azurerm_api_management_product_policy" "jwt_policy" {
  product_id          = azurerm_api_management_product.jwt.product_id
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group
  xml_content         = file("${path.module}/../../../Resources/Policies/ProductPolicies/unifiedaigateway-product-jwt.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

resource "azurerm_api_management_product_policy" "subscription_policy" {
  product_id          = azurerm_api_management_product.subscription.product_id
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group
  xml_content         = file("${path.module}/../../../Resources/Policies/ProductPolicies/unifiedaigateway-product-subscription.xml")

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Default subscription for testing
resource "azurerm_api_management_subscription" "unified_ai_subscription" {
  api_management_name = local.apim_name
  resource_group_name = local.apim_resource_group
  display_name        = "Unified AI Gateway Subscription"
  product_id          = azurerm_api_management_product.subscription.id
  state               = "active"

  depends_on = [data.azurerm_api_management.apim_readiness_check]
}

# Store subscription key in Key Vault
resource "azurerm_key_vault_secret" "apim_subscription_key" {
  name         = "UAIG-APIM-SUBSCRIPTION-KEY"
  value        = azurerm_api_management_subscription.unified_ai_subscription.primary_key
  key_vault_id = var.key_vault_id
}

