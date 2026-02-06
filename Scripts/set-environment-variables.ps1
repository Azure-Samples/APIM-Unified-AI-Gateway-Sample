# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates VS Code REST Client settings from AZD outputs and resolved secrets.

.DESCRIPTION
    This script is the post-provision hook for the Unified AI Gateway sample.
    It extracts environment variables from AZD outputs (endpoints, IDs, names) and
    retrieves resolved secrets from the AZD hook environment to create a settings
    file for the VS Code REST Client extension.

.PARAMETER None
    This script does not accept parameters. Configuration is read from environment variables.

.INPUTS
    None. Environment variables are read from the AZD hook execution context.

.OUTPUTS
    - .azure/{env-name}/vscode-settings.json - Generated settings file
    - .vscode/settings.json - Applied settings for VS Code REST Client

.EXAMPLE
    .\set-environment-variables.ps1
    
    Automatically called by azure.yaml post-provision hook with secrets resolved.
    Can also be manually executed for troubleshooting or re-synchronization.

.NOTES
    File Name      : set-environment-variables.ps1
    Prerequisite   : Azure Developer CLI (azd), Terraform deployment completed
    Copyright      : Microsoft
#>

[CmdletBinding()]
param()

# Constants
Set-Variable -Name EXPECTED_ENDPOINT_COUNT -Value 3 -Option ReadOnly

Write-Host "🔄 Generating VS Code REST Client settings from AZD outputs..." -ForegroundColor Yellow

#region Helper Functions
function Get-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$VarName
    )
    
    # Get value from environment variable
    $value = Get-Item "env:$VarName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    
    # Check if variable exists and is non-empty
    if ([string]::IsNullOrEmpty($value)) {
        Write-Error "❌ Required variable '$VarName' not found or empty in environment. Check that Terraform deployment completed successfully and AZD hook resolved secrets"
        exit 1
    }
    
    return $value
}

function Convert-EndpointArrayToVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ArrayEnvVarName,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputVarPrefix,
        
        [Parameter()]
        [int]$ExpectedCount = $EXPECTED_ENDPOINT_COUNT
    )
    
    $endpointsJson = Get-Item "env:$ArrayEnvVarName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    if (-not $endpointsJson) {
        Write-Host "⚠️  $ArrayEnvVarName not found in environment - skipping" -ForegroundColor Yellow
        return
    }
    
    try {
        # Unescape JSON: azd stores arrays in .env as "[\"url1\",\"url2\"]" so we convert \" to " for valid JSON
        $endpoints = ($endpointsJson.Replace('\"', '"') | ConvertFrom-Json -ErrorAction Stop)
 
        # Validate expected count
        if ($endpoints.Count -ne $ExpectedCount) {
            Write-Warning "⚠️  Expected $ExpectedCount endpoints for $ArrayEnvVarName, but found $($endpoints.Count). This may indicate an incomplete deployment"
        }
        
        # Set environment variables for each endpoint
        for ($i = 0; $i -lt $endpoints.Count; $i++) {
            $regionIndex = $i + 1
            $varName = "${OutputVarPrefix}_region${regionIndex}_endpoint"
            Set-Item "env:$varName" -Value $endpoints[$i]
        }
        
        Write-Host "✅ Generated $($endpoints.Count) endpoint variables for $OutputVarPrefix" -ForegroundColor Green
    } catch {
        Write-Warning "⚠️  Failed to process $ArrayEnvVarName : $_"
    }
}

#endregion

#region Main Script Logic

# Find project root by looking for azure.yaml
$currentDir = Get-Location
while ($currentDir -and !(Test-Path (Join-Path $currentDir "azure.yaml"))) {
    $currentDir = Split-Path $currentDir -Parent
}

if (-not $currentDir) {
    Write-Error "❌ Project root not found - azure.yaml not found in current directory or any parent directory. Ensure you are running this script from within the project directory"
    exit 1
}

$projectRoot = $currentDir
Write-Host "📁 Project root found: $projectRoot" -ForegroundColor Green

# Get the AZD environment name
$azdEnvName = $env:AZURE_ENV_NAME

# Validate that the AZD environment is set
if (-not $azdEnvName) {
    Write-Error "❌ AZURE_ENV_NAME environment variable not set"
    exit 1
}

$azdEnvDir = Join-Path $projectRoot ".azure\$azdEnvName"

if (-not (Test-Path $azdEnvDir)) {
    Write-Error "❌ AZD environment directory not found: $azdEnvDir. Run 'azd provision' first"
    exit 1
}

$outputSettingsPath = Join-Path $azdEnvDir "vscode-settings.json"

# Validate AZD environment setup
Write-Host "🔍 Validating AZD environment setup..." -ForegroundColor Cyan
Write-Host "   All variables retrieved from environment (Terraform outputs + resolved secrets)" -ForegroundColor Gray

# Transform Foundry endpoint arrays into numbered variables
Write-Host "🔄 Processing Foundry endpoints..." -ForegroundColor Cyan
Convert-EndpointArrayToVariables -ArrayEnvVarName "foundry_premium_endpoints" -OutputVarPrefix "foundry_premium"
Convert-EndpointArrayToVariables -ArrayEnvVarName "foundry_standard_endpoints" -OutputVarPrefix "foundry_standard"

# Build VS Code settings object
Write-Host "🔄 Creating VS Code settings from environment variables..." -ForegroundColor Cyan
Write-Host "Environment name: $azdEnvName" -ForegroundColor Gray

# Create the settings structure with ordered hashtable
$envVars = [ordered]@{}
$settings = @{
    "rest-client.environmentVariables" = @{
        $azdEnvName = $envVars
    }
}

# Add all variables to environment settings
try {
    # Define non-secret variables only (endpoints, IDs, names - no keys or secrets)
    # Variables are explicitly listed (not dynamically discovered) because azd hook resolves secrets that aren't in .env
    # Casing must be as shown
    $requiredVarNames = @(
        "AZURE_SUBSCRIPTION_ID",
        "apim_gateway_url",
        "entra_app_id",
        "entra_app_identifier_uri",
        "tenant_id",
        "key_vault_name",
        "foundry_inference_endpoint",
        "apim_resource_id",
        "apim_name",
        "gemini_endpoint",
        "foundry_premium_region1_endpoint",
        "foundry_premium_region2_endpoint",
        "foundry_premium_region3_endpoint",
        "foundry_standard_region1_endpoint",
        "foundry_standard_region2_endpoint",
        "foundry_standard_region3_endpoint"
    )
    
    # Process all required variables
    foreach ($varName in $requiredVarNames) {
        $value = Get-EnvironmentVariable -VarName $varName
        
        # Special handling for entra_app_identifier_uri (remove api:// prefix for JWT scope in OAuth token requests)
        if ($varName -eq "entra_app_identifier_uri" -and $value -match "^api://(.+)$") {
            # Strip api:// prefix for JWT compatibility (OAuth scope expects just the GUID)
            $value = $matches[1]
            Write-Host "🔧 Stripped api:// prefix from entra_app_identifier_uri for JWT compatibility" -ForegroundColor Gray
        }
        
        $envVars[$varName] = $value
    }
    
    Write-Host "✅ All $($requiredVarNames.Count) non-secret variables added successfully" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to process environment variables: $_"
    exit 1
}

# Add resolved secrets from AZD hook environment variables
Write-Host "🔐 Adding resolved secrets from AZD hook..." -ForegroundColor Cyan

# Define secret variable names (azure.yaml resolves these with final names)
$secretVarNames = @(
    "apim_subscription_key",
    "entra_app_client_secret",
    "foundry_inference_key",
    "foundry_premium_region1_key",
    "foundry_premium_region2_key",
    "foundry_premium_region3_key",
    "foundry_standard_region1_key",
    "foundry_standard_region2_key",
    "foundry_standard_region3_key",
    "gemini_api_key"
)

# Add each secret if it exists (pass through directly, no renaming needed)
foreach ($varName in $secretVarNames) {
    $value = Get-EnvironmentVariable -VarName $varName
    $envVars[$varName] = $value
}

Write-Host "✅ Added $($secretVarNames.Count) resolved secret(s) to settings" -ForegroundColor Green

# Convert to JSON
try {
    # Sort environment variables alphabetically for consistent output
    $sortedEnv = [ordered]@{}
    $envVars.Keys | Sort-Object -Culture 'en-US' | ForEach-Object {
        $sortedEnv[$_] = $envVars[$_]
    }
    
    # Rebuild settings with sorted environment variables
    $settings = @{
        "rest-client.environmentVariables" = @{
            $azdEnvName = $sortedEnv
        }
    }
    
    $settingsJson = $settings | ConvertTo-Json -Depth 10 -ErrorAction Stop
    Write-Host "✅ VS Code settings object constructed successfully" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to build VS Code settings object: $_"
    exit 1
}


# Write the populated settings file to environment folder
try {
    Set-Content -Path $outputSettingsPath -Value $settingsJson -Encoding UTF8 -ErrorAction Stop
    Write-Host "✅ VS Code settings file created successfully" -ForegroundColor Green
    Write-Host "📂 Location: $outputSettingsPath" -ForegroundColor Cyan
} catch {
    Write-Error "❌ Failed to create VS Code settings file: $_"
    exit 1
}

# Verify the settings file was created properly
if (Test-Path $outputSettingsPath) {
    $settingsSize = (Get-Item $outputSettingsPath).Length
    Write-Host "📊 Settings file: $settingsSize bytes" -ForegroundColor Green
} else {
    Write-Error "❌ Settings file was not created successfully"
    exit 1
}

# Automatically copy the generated settings to .vscode/settings.json
$vscodeSettingsPath = Join-Path $projectRoot ".vscode" "settings.json"
$vscodeDir = Join-Path $projectRoot ".vscode"

# Ensure .vscode directory exists
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
    Write-Host "📁 Created .vscode directory" -ForegroundColor Cyan
}

# Copy the generated settings file
try {
    Copy-Item -Path $outputSettingsPath -Destination $vscodeSettingsPath -Force
    Write-Host "✅ VS Code settings automatically applied!" -ForegroundColor Green
} catch {
    Write-Warning "⚠️  Could not automatically copy settings file: $($_.Exception.Message). Manual copy required from: $outputSettingsPath"
}

Write-Host ""
Write-Host "🧪 Ready to Test - REST Client Configured:" -ForegroundColor Yellow
Write-Host "1. 🚀 Environment variables and secrets are now available for testing with REST Client" -ForegroundColor Cyan
Write-Host "2. 🔐 Secrets automatically retrieved from Key Vault via AZD hook and included in settings" -ForegroundColor Green
Write-Host "3. 📂 Settings applied: $vscodeSettingsPath" -ForegroundColor Gray
Write-Host ""
Write-Host "🎉 Environment setup complete! VS Code REST Client ready to use." -ForegroundColor Green

#endregion