# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# ============================================================================
# Entra ID Module Variables
# ============================================================================

variable "naming_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store the client secret"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all security resources"
  type        = map(string)
  default     = {}
}