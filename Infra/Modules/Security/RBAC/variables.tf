# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# RBAC Module Variables
# ============================================================================

variable "service_principal_object_id" {
  description = "Object ID of the service principal for role assignments"
  type        = string
}

variable "apim_principal_id" {
  description = "Principal ID of the APIM system-assigned managed identity for backend authentication to Azure OpenAI and Foundry"
  type        = string
}

variable "foundry_account_ids" {
  description = "List of Foundry AI Services account resource IDs for role assignments"
  type        = list(string)
  default     = []
}

variable "apim_id" {
  description = "API Management resource ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all RBAC resources"
  type        = map(string)
  default     = {}
}