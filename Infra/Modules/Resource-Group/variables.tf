# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "Name of existing resource group (empty creates new)"
  type        = string
  default     = ""

  validation {
    condition     = var.resource_group_name == "" || can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be empty (to create new resource group) or a valid Azure resource group name (1-90 chars, alphanumeric, periods, underscores, hyphens, parentheses)."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "resource_prefix" {
  description = "Resource token for naming"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}