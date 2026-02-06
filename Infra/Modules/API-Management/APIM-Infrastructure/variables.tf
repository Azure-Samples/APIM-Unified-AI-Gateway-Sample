# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_prefix" {
  description = "Unique resource token for naming"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email for APIM service"
  type        = string
  default     = "admin@example.com"
}

variable "apim_sku_name" {
  description = "APIM SKU"
  type        = string
  default     = "BasicV2_1"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}