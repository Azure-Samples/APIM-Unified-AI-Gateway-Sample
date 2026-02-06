# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "apim_sku_name" {
  description = "SKU name for API Management (format: SKU_Capacity, e.g., Developer_1)"
  type        = string
  default     = "BasicV2_1"
  validation {
    condition = var.apim_sku_name == "" || contains([
      "Developer_1", "Basic_1", "Basic_2",
      "Standard_1", "Standard_2",
      "Premium_1", "Premium_2", "Premium_4", "Premium_6",
      "BasicV2_1", "StandardV2_1", "PremiumV2_1"
    ], var.apim_sku_name)
    error_message = "Invalid APIM SKU. Consumption tier is NOT supported - this sample uses rate-limit-by-key policy which is incompatible with Consumption tier. Valid format: SKU_Capacity (e.g., Developer_1, StandardV2_1)."
  }
}

variable "entra_app_client_secret_kv_ref" {
  type        = string
  default     = ""
  description = "Key Vault reference for existing Entra ID app client secret. Required when using existing_entra_app_id. Format: akvs://{subscription_id}/{key_vault_name}/{secret_name}"

  validation {
    condition     = var.entra_app_client_secret_kv_ref == "" || can(regex("^akvs://[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/[^/]+/[^/]+$", var.entra_app_client_secret_kv_ref))
    error_message = "entra_app_client_secret_kv_ref must be either empty string or a valid Key Vault reference in format: akvs://{subscription_id}/{key_vault_name}/{secret_name}"
  }

  validation {
    condition = (
      var.existing_entra_app_id == "" ||
      (var.existing_entra_app_id != "" && var.entra_app_client_secret_kv_ref != "")
    )
    error_message = "entra_app_client_secret_kv_ref is required when existing_entra_app_id is specified."
  }
}

variable "environment_name" {
  type        = string
  description = "Environment name used for resource naming and tags."
  default     = "dev"
}

variable "existing_apim_name" {
  type        = string
  default     = ""
  description = "Name of existing APIM instance to use. Set to empty string to create new APIM."
}

variable "existing_apim_rg" {
  type        = string
  default     = ""
  description = "Resource group containing existing APIM. Required only when existing_apim_name is set."

  validation {
    condition = (
      var.existing_apim_name == "" ||
      (var.existing_apim_name != "" && var.existing_apim_rg != "")
    )
    error_message = "existing_apim_rg is required when existing_apim_name is specified."
  }
}

variable "existing_appinsight_name" {
  type        = string
  default     = ""
  description = "Name of existing Application Insights instance to use. Set to empty string to create new Application Insights."
}

variable "existing_appinsight_rg" {
  type        = string
  default     = ""
  description = "Resource group containing existing Application Insights. Required only when existing_appinsight_name is set."

  validation {
    condition = (
      var.existing_appinsight_name == "" ||
      (var.existing_appinsight_name != "" && var.existing_appinsight_rg != "")
    )
    error_message = "existing_appinsight_rg is required when existing_appinsight_name is specified."
  }
}

variable "existing_entra_app_id" {
  type        = string
  default     = ""
  description = "Client ID (Application ID) of existing Entra ID app registration to use. Set to empty string to create new app registration."

  validation {
    condition     = var.existing_entra_app_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.existing_entra_app_id))
    error_message = "existing_entra_app_id must be either empty string or a valid GUID format."
  }
}

variable "existing_logger_name" {
  type        = string
  default     = ""
  description = "Name of existing Application Insights logger in APIM. If provided, Terraform will use this logger instead of creating a new one."
}

variable "foundry_inference_region" {
  type        = string
  description = "Azure region for Foundry with inference tier deployment."
  default     = "eastus"
  validation {
    condition     = var.foundry_inference_region == "" || can(regex("^[a-z0-9]+$", var.foundry_inference_region))
    error_message = "foundry_inference_region must be empty or a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_premium_region_1" {
  type        = string
  description = "Primary Azure region for Foundry with premium tier deployment."
  default     = "eastus"
  validation {
    condition     = var.foundry_premium_region_1 == "" || can(regex("^[a-z0-9]+$", var.foundry_premium_region_1))
    error_message = "foundry_premium_region_1 must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_premium_region_2" {
  type        = string
  description = "Secondary Azure region for Foundry with premium tier deployment (optional)."
  default     = "westus"
  validation {
    condition     = var.foundry_premium_region_2 == "" || can(regex("^[a-z0-9]+$", var.foundry_premium_region_2))
    error_message = "foundry_premium_region_2 must be empty or a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_premium_region_3" {
  type        = string
  description = "Tertiary Azure region for Foundry with premium tier deployment (optional)."
  default     = "northcentralus"
  validation {
    condition     = var.foundry_premium_region_3 == "" || can(regex("^[a-z0-9]+$", var.foundry_premium_region_3))
    error_message = "foundry_premium_region_3 must be empty or a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_standard_region_1" {
  type        = string
  description = "Primary Azure region for Foundry with standard tier deployment."
  default     = "eastus"
  validation {
    condition     = var.foundry_standard_region_1 == "" || can(regex("^[a-z0-9]+$", var.foundry_standard_region_1))
    error_message = "foundry_standard_region_1 must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_standard_region_2" {
  type        = string
  description = "Secondary Azure region for Foundry with standard tier deployment (optional)."
  default     = "westus"
  validation {
    condition     = var.foundry_standard_region_2 == "" || can(regex("^[a-z0-9]+$", var.foundry_standard_region_2))
    error_message = "foundry_standard_region_2 must be empty or a valid Azure region name (lowercase, no spaces)."
  }
}

variable "foundry_standard_region_3" {
  type        = string
  description = "Tertiary Azure region for Foundry with standard tier deployment (optional)."
  default     = "northcentralus"
  validation {
    condition     = var.foundry_standard_region_3 == "" || can(regex("^[a-z0-9]+$", var.foundry_standard_region_3))
    error_message = "foundry_standard_region_3 must be empty or a valid Azure region name (lowercase, no spaces)."
  }
}

variable "gemini_endpoint" {
  type        = string
  description = "External Gemini API base endpoint (https URL)."
  default     = "https://generativelanguage.googleapis.com"
  validation {
    condition     = var.gemini_endpoint == "" || can(regex("^https://[A-Za-z0-9.-]+(/.*)?$", var.gemini_endpoint))
    error_message = "gemini_endpoint must be empty (to use default) or start with https:// and contain a valid host name."
  }
}

variable "gemini_secret_kv_ref" {
  type        = string
  description = "Name of the Key Vault secret containing the Gemini API key. Can be either a simple secret name (e.g., 'UAIG-GEMINI-API-KEY') or an azd Key Vault reference (e.g., 'akvs://subscription-id/vault-name/secret-name')."
  validation {
    condition = (
      length(var.gemini_secret_kv_ref) > 0 &&
      (
        # Allow simple secret name (alphanumeric and hyphens only)
        can(regex("^[a-zA-Z0-9-]+$", var.gemini_secret_kv_ref)) ||
        # Allow akvs:// format with exactly 5 segments when split by /
        (can(regex("^akvs://", var.gemini_secret_kv_ref)) && length(split("/", var.gemini_secret_kv_ref)) == 5)
      )
    )
    error_message = "gemini_secret_kv_ref must be either a simple secret name (alphanumeric with hyphens) or a valid azd Key Vault reference in format 'akvs://subscription-id/vault-name/secret-name'."
  }
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault containing secrets (e.g., Gemini API key)."
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 characters and contain only alphanumerics and hyphens."
  }
}

variable "key_vault_resource_group" {
  type        = string
  description = "Resource group containing the Key Vault."
  validation {
    condition     = length(var.key_vault_resource_group) > 0
    error_message = "key_vault_resource_group is required."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resource group, APIM, and App Insights. OpenAI and Foundry use separate region variables."
  default     = "westus"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "publisher_email" {
  type        = string
  description = "Contact email used for API Management publisher metadata (display + notifications)."
  default     = "admin@example.com"
  validation {
    condition     = var.publisher_email == "" || can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.publisher_email))
    error_message = "publisher_email must be a valid email address or empty string."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name. Leave empty/unset to create a new resource group, or provide existing resource group name to use existing."
  default     = ""
  validation {
    condition     = var.resource_group_name == "" || can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be empty (to create new resource group) or a valid Azure resource group name (1-90 chars, alphanumeric, periods, underscores, hyphens, parentheses)."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy resources into."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription GUID."
  }
}
