# GitHub Copilot Instructions

This file provides guidance to GitHub Copilot when working on code changes in this repository.

## Repository Context - SAMPLE/DEMO

**This is a SAMPLE repository designed for learning and demonstration purposes.**

- **NOT a production application** - Does not implement production-level security, scalability, or reliability patterns
- **Fresh deployments only** - Users deploy with `azd up` to create new infrastructure from scratch
- **No existing state** - There is no production data, no existing users, no live infrastructure to preserve
- **No migration scenarios** - Users tear down and redeploy; there is nothing to migrate from
- **Breaking changes welcome** - Each deployment is independent; no backward compatibility needed
- **Simplified patterns** - Prioritizes clarity and learning over enterprise complexity

**When implementing changes:**
- Focus on clean, understandable code that demonstrates concepts
- Do NOT add enterprise patterns (feature flags, gradual rollouts, A/B testing) unless specifically requested
- Do NOT plan migration phases or assume existing infrastructure
- Do NOT add production hardening unless it's core to the feature being demonstrated

## Project Knowledge

### Deployment Model

This sample uses **Azure Developer CLI (azd)** to provision infrastructure via **Terraform**:

1. `main.tfvars.json` defines variable values for azd
2. azd passes these values to Terraform via `variables.tf`

**CRITICAL: Variable names must match exactly (case-sensitive) between `main.tfvars.json` and `variables.tf`.**

```
main.tfvars.json          variables.tf
─────────────────         ────────────────
"resourceGroup"    →      variable "resourceGroup"
"location"         →      variable "location"
```

### Tech Stack
- **Infrastructure as Code:** Terraform >= 1.7.0, Azure Resource Manager (ARM)
- **Cloud Platform:** Microsoft Azure
  - Azure API Management (APIM)
  - Azure AI Foundry (AI Services API 2025-06-01)
  - Azure OpenAI Service (GPT-4o, GPT-4o-mini)
  - Azure Cognitive Services
  - Azure Application Insights
  - Azure Entra ID (formerly Azure AD)
- **Terraform Providers:** azurerm ~> 3.114, azuread ~> 2.49, azapi >= 2.7.0, random ~> 3.6, local ~> 2.5
- **DevOps & Automation:** Azure Developer CLI (azd), PowerShell 7+, REST Client
- **AI Models & APIs:** 
  - Azure OpenAI (GPT-4o, GPT-4o-mini)
  - Azure AI Foundry (Phi-4 model v7)
  - Google Gemini 2.0 Flash (external API)
- **API Management:** Circuit breakers, load balancing, JWT authentication, managed identities
- **Policy Languages:** APIM policy XML (C# 7 syntax compliant)

### File Structure

```
├── .github/                      # GitHub configuration and automation
│   ├── workflows/                # GitHub Actions CI/CD pipelines
│
├── Infra/                        # Terraform infrastructure as code
│   ├── *.tf files                # Infrastructure definitions 
│   └── Resources/                # APIM policy and configuration files
│       ├── Policies/             # API and Product policy XML files
│       │   ├── APIPolicies/      # API policies for APIM
│       │   └── ProductPolicies/  # Product policies for APIM
│       ├── Fragments/            # Policy fragments
│       ├── Schema/               # API schema definitions (JSON)
│       └── Queries/              # Application Insights KQL queries
│
├── Scripts/                      # PowerShell automation scripts
│
├── Tests/                        # REST Client HTTP test files that validate APIM API gateway
│
└── Root files                    # azure.yaml (for AZD), README.md, architecture guide
```

## Backward Compatibility

**Coding changes do NOT need to maintain backward compatibility for scenarios.**

- You are free to make changes to APIs, interfaces, and implementations
- Focus on implementing the best solution without constraints of backward compatibility
- Prioritize clean, maintainable code over compatibility with previous versions

## Documentation Updates

**All related documentation files MUST be updated to reflect coding changes.**

When you make code changes, you MUST also update:

- `README.md` - Update if the changes affect usage, setup, or high-level architecture
- Any `.md` files in the repository that explain the code itself
- File header comments that describe the file's purpose, variables, or dependencies
- **KQL queries** - When modifying `<trace>` elements in policy fragments, update the corresponding queries in `Infra/Resources/Queries/` to stay in sync

**Requirements:**
- Documentation updates should be made in the same commit/PR as the code changes
- Ensure documentation accurately reflects the new implementation
- Update examples and code snippets to match new behavior
- Remove or update any outdated information

## Code Comments

**Comments in code files MUST always be updated to reflect the actual implementation.**

When you modify code:

- ✅ **DO:** Update existing comments to match the new implementation
- ✅ **DO:** Remove comments that are no longer accurate or relevant
- ✅ **DO:** Add comments where the new implementation needs clarification
- ✅ **DO:** Ensure inline documentation (JSDoc, XML docs, etc.) matches function signatures and behavior
- ❌ **DON'T:** Leave outdated comments that describe old behavior
- ❌ **DON'T:** Leave TODO comments for changes you've already implemented
- ❌ **DON'T:** Add comments that simply restate what the code obviously does
- ❌ **DON'T:** Reference previous implementations or explain why changes were made compared to old code
- ❌ **DON'T:** Include historical context like "previously this did X" or "changed from Y to Z"

**Comment Quality:**
- Comments should explain WHY, not WHAT (the code shows what)
- Keep comments concise and up-to-date with the implementation
- Write comments as if the code is brand new - no historical references (this is a sample, not a production codebase with change history)

## Summary

When making changes to this repository:

1. **This is a SAMPLE** - Not production; no migration, no existing state, fresh deployments only
2. **No backward compatibility required** - Implement the best solution
3. **Update all documentation** - Keep README and .md files in sync with code
4. **Update all comments** - Ensure comments match actual implementation
