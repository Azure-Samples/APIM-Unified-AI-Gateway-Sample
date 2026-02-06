# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Auto-discovers Key Vault name and resource group from AZD secret references.

.DESCRIPTION
    This script is the pre-provision hook for the Unified AI Gateway sample.
    It extracts Key Vault details from the GEMINI_SECRET_KV_REF environment variable
    (in akvs:// format) and queries Azure to discover the resource group.
    Sets KEY_VAULT_NAME and KEY_VAULT_RG for Terraform deployment.

.PARAMETER None
    This script does not accept parameters. Configuration is read from environment variables.

.INPUTS
    None. Environment variable GEMINI_SECRET_KV_REF is read from the AZD environment.

.OUTPUTS
    Sets AZD environment variables: key_vault_name and key_vault_rg

.EXAMPLE
    .\keyvault-lookup.ps1
    
    Automatically called by azure.yaml pre-provision hook.
    Can also be manually executed to re-discover Key Vault configuration.

.NOTES
    File Name      : keyvault-lookup.ps1
    Prerequisite   : Azure CLI (az), GEMINI_SECRET_KV_REF set via 'azd env set-secret'
    Copyright      : Microsoft
#>

[CmdletBinding()]
param()

Write-Host "🔍 Auto-discovering Key Vault configuration..." -ForegroundColor Cyan

# Get the required GEMINI_SECRET_KV_REF
$secretRef = $env:GEMINI_SECRET_KV_REF

if (-not $secretRef) {
    Write-Error "❌ GEMINI_SECRET_KV_REF not set. Set the Gemini Key Vault secret reference: azd env set-secret GEMINI_SECRET_KV_REF"
    exit 1
}

# Parse akvs://subscription-id/vault-name/secret-name
# Regex captures: $matches[1]=subscription-id, $matches[2]=vault-name, $matches[3]=secret-name
if ($secretRef -notmatch '^akvs://([^/]+)/([^/]+)/([^/]+)$') {
    Write-Error "❌ Invalid secret reference format: $secretRef. Expected format: akvs://subscription-id/vault-name/secret-name. Retry: azd env set-secret GEMINI_SECRET_KV_REF"
    exit 1
}

$subscriptionId = $matches[1]
$keyVaultName = $matches[2]

Write-Host "  Subscription: $subscriptionId" -ForegroundColor Gray
Write-Host "  Key Vault: $keyVaultName" -ForegroundColor Gray

# Query Azure for resource group using Azure CLI
$resourceGroupName = az keyvault show --name $keyVaultName --subscription $subscriptionId --query resourceGroup -o tsv 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resourceGroupName)) {
    Write-Error "❌ Failed to query Key Vault '$keyVaultName'. Manually set Key Vault details: azd env set KEY_VAULT_NAME $keyVaultName; azd env set KEY_VAULT_RG <resource-group-name>"
    exit 1
}

# Set environment variables
azd env set key_vault_name $keyVaultName | Out-Null
azd env set key_vault_rg $resourceGroupName | Out-Null

Write-Host "✅ Auto-discovered: $keyVaultName in $resourceGroupName" -ForegroundColor Green
