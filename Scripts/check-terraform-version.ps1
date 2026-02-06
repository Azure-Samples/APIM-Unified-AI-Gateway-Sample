# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates that Terraform 1.9.0 or later is installed.

.DESCRIPTION
    This script checks the installed Terraform version and ensures it meets
    the minimum requirement of 1.9.0, which is needed for enhanced variable
    validation features used in this sample.

.PARAMETER None
    This script does not accept parameters.

.INPUTS
    None.

.OUTPUTS
    Exits with code 0 if version is valid, exits with code 1 if invalid.

.EXAMPLE
    .\check-terraform-version.ps1
    
    Automatically called by azure.yaml pre-provision hook.

.NOTES
    File Name      : check-terraform-version.ps1
    Prerequisite   : Terraform CLI 1.9.0 or later
    Copyright      : Microsoft
#>

[CmdletBinding()]
param()

Write-Host "🔍 Checking Terraform version..." -ForegroundColor Cyan

$terraformVersion = terraform version -json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version

if (-not $terraformVersion) {
    Write-Error "❌ Terraform is not installed or not in PATH. Install Terraform 1.9.0 or later."
    exit 1
}

# Parse version (e.g., "1.9.5" -> [1, 9, 5])
$versionParts = $terraformVersion -split '\.' | ForEach-Object { [int]$_ }
$major = $versionParts[0]
$minor = $versionParts[1]

if ($major -lt 1 -or ($major -eq 1 -and $minor -lt 9)) {
    Write-Error "❌ Terraform version $terraformVersion detected. This sample requires Terraform 1.9.0 or later due to enhanced variable validation features. Please upgrade: https://developer.hashicorp.com/terraform/install"
    exit 1
}

Write-Host "  ✓ Terraform $terraformVersion" -ForegroundColor Gray
Write-Host ""
