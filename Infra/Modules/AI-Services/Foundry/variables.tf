# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# Foundry Module Variables
# ============================================================================

variable "resource_group_id" {
  description = "Resource ID of the parent resource group"
  type        = string
}

variable "region" {
  description = "Azure region for Foundry account deployment"
  type        = string
}

variable "resource_prefix" {
  description = "Naming prefix for resources"
  type        = string
}

variable "foundry_name_suffix" {
  description = "Unique identifier suffix for this Foundry instance (e.g., 'phi4', 'gpt4o-region1')"
  type        = string
}

variable "deployment_name" {
  description = "Name of the model deployment"
  type        = string
}

variable "model_name" {
  description = "Name of the model to deploy"
  type        = string
}

variable "model_format" {
  description = "Format of the model (OpenAI or Microsoft)"
  type        = string
  default     = "OpenAI"
}

variable "model_version" {
  description = "Version of the model"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the deployment (e.g., 'Standard', 'GlobalStandard')"
  type        = string
}

variable "capacity" {
  description = "Capacity/quota for the deployment"
  type        = number
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "Key Vault resource ID for storing Foundry access key"
  type        = string
}
