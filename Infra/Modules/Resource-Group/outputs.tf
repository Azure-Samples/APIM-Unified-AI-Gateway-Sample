# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "resource_group_name" {
  description = "Name of the resource group (created or existing)"
  value       = local.resource_group_name
}

output "location" {
  description = "Location of the resource group"
  value       = local.resource_group_location
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = local.resource_group_id
}