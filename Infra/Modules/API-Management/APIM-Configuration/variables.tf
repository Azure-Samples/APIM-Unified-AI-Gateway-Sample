# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "apim_id" {
  description = "API Management service resource ID (can be from newly created or existing APIM)"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ApiManagement/service/[^/]+$", var.apim_id))
    error_message = "apim_id must be a valid Azure API Management resource ID."
  }
}

variable "apim_gateway_url" {
  description = "API Management gateway URL"
  type        = string
}

variable "app_insights_id" {
  description = "Application Insights resource ID (can be from newly created or existing App Insights)"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Insights/components/[^/]+$", var.app_insights_id))
    error_message = "app_insights_id must be a valid Azure Application Insights resource ID."
  }
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
}

variable "app_insights_instrumentation_key_secret_id" {
  description = "Key Vault secret ID for Application Insights instrumentation key (APIM will retrieve using managed identity). If null, uses direct key."
  type        = string
  default     = null
}

variable "use_key_vault_for_appinsights" {
  description = "Whether to use Key Vault for storing App Insights instrumentation key (true for new App Insights, false for existing)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Security variables
variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "entra_app_id" {
  description = "Entra ID application client ID"
  type        = string
}

# AI Services variables
variable "foundry_inference_endpoint" {
  description = "Foundry inference tier endpoint URL"
  type        = string
}

# Foundry premium tier variables
variable "foundry_premium_endpoints" {
  description = "Foundry premium tier endpoints array (3 regions)"
  type        = list(string)
}

# Foundry standard tier variables
variable "foundry_standard_endpoints" {
  description = "Foundry standard tier endpoints array (3 regions)"
  type        = list(string)
}

# External service variables
variable "gemini_key_vault_secret_id" {
  description = "Key Vault secret ID for Gemini API key (APIM will retrieve directly using managed identity)"
  type        = string
}

variable "gemini_endpoint" {
  description = "Gemini API endpoint URL"
  type        = string
  default     = "https://generativelanguage.googleapis.com"
}

variable "create_appinsights_logger" {
  description = "Whether to create a new Application Insights logger. Set to false if APIM already has a logger configured."
  type        = bool
  default     = true
}

variable "existing_logger_name" {
  description = "Name of existing Application Insights logger in APIM. Required if create_appinsights_logger is false."
  type        = string
  default     = "appinsights-logger"
}

variable "key_vault_id" {
  description = "Key Vault resource ID for storing the APIM subscription key"
  type        = string
}