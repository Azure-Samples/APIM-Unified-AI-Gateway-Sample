# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">= 1.9.0"

  backend "local" {
    # azd will override this path when running terraform commands
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.49"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7"
    }
  }
}

provider "azurerm" {
  features {}
  # Avoid long waits/hangs auto-registering resource providers when principal lacks permission.
  # This uses the new property introduced in azurerm provider v4.x to skip registration.
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
}

provider "azuread" {}

provider "azapi" {
  use_msi         = false
  use_cli         = true
  subscription_id = var.subscription_id
}

provider "local" {}
