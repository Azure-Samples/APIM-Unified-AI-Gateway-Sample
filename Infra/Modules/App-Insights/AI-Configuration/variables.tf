# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "app_insights_id" {
  description = "Application Insights resource ID (can be from newly created or existing App Insights)"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Insights/components/[^/]+$", var.app_insights_id))
    error_message = "app_insights_id must be a valid Azure Application Insights resource ID."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}