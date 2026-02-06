---
description: 'Guidelines for editing APIM policy XML files and policy fragments'
applyTo: '**/*.xml'
---

# APIM Policy XML Guidelines

This guide provides instructions for working with Azure API Management (APIM) policy XML files.

## Suggested Policy File Structure

A **suggested** folder structure for APIM policy files:

```text
Infra/
└── Resources/
    ├── Policies/
    │   ├── APIPolicies/        # API policies
    │   │   └── *.xml
    │   └── ProductPolicies/    # Product-level policies
    │       └── *.xml
    └── Fragments/              # Injected policy fragments
        └── *.xml
```

## XML Content Rules

**CRITICAL: Do NOT escape XML content**

When making changes to policy `.xml` files:

- ❌ **DON'T:** Add escape characters to XML content in existing or new files
- ❌ **DON'T:** Escape special characters like `<`, `>`, `&`, `"`, `'`
- ❌ **DON'T:** Use HTML entities (e.g., `&lt;`, `&gt;`, `&amp;`)
- ✅ **DO:** Preserve the XML structure exactly as-is without escaping
- ✅ **DO:** Keep XML formatting clean and readable
- ✅ **DO:** Maintain consistent indentation

## C# Expressions in Policies

APIM policies and fragments use C# expressions within `@()` or `@{}` syntax. When writing C# expressions:

- **Use C# 7 syntax only** - Do not use C# 8+ features
- Keep expressions concise and readable
- Do not escape characters within C# expressions
- Test expressions are syntactically valid C# 7

For valid policy expression syntax and examples, refer to: [API Management policy expressions](https://learn.microsoft.com/azure/api-management/api-management-policy-expressions)

## Variable Best Practices

### Use safe variable access

Use `GetValueOrDefault` with meaningful defaults:

```xml
<set-variable name="user" value="@(context.Variables.GetValueOrDefault<string>("user-id", "anonymous"))" />
```

### Check variable existence

For required variables, fail fast:

```xml
<choose>
    <when condition="@(!context.Variables.ContainsKey("required-var"))">
        <return-response>
            <set-status code="500" reason="Internal Server Error" />
        </return-response>
    </when>
</choose>
```

### Minimize variable access

Consolidate multiple accesses into single expressions:

```xml
<set-variable name="result" value="@{
    var a = context.Variables.GetValueOrDefault<string>("var-a", "");
    var b = context.Variables.GetValueOrDefault<string>("var-b", "");
    return $"{a}:{b}";
}" />
```

### Use consistent types

Use `@()` for explicit typing. For booleans, use `@(true)` or `@(false)`, not strings `"true"` or `"false"`:

```xml
<!-- Correct: boolean type -->
<set-variable name="enabled" value="@(true)" />
<when condition="@(context.Variables.GetValueOrDefault<bool>("enabled", false))">

<!-- Wrong: string type requires string comparison -->
<set-variable name="enabled" value="true" />
```

### Preserve request body across fragments

When fragments read the request body, use `preserveContent: true` to keep it available for downstream fragments and backend forwarding:

```xml
<set-variable name="body-content" value="@(context.Request.Body.As<string>(preserveContent: true))" />
```

## Policy Fragment Guidelines

For detailed guidance on reusable policy fragments, refer to: [Reuse policy configurations in Azure API Management](https://learn.microsoft.com/azure/api-management/policy-fragments)

When creating or modifying policy fragments:

- Each fragment should be self-contained and reusable
- Use meaningful fragment names that describe the functionality
- Include XML comments to document the fragment's purpose

### Inject fragments based on scope

All fragments must be injected using `include-fragment` at either the product policy or API policy level. Fragments not injected anywhere are orphaned and unused.

Divide fragment responsibilities by policy scope:

- **Product policy**: Inject fragments for product-specific behavior
- **API policy**: Inject fragments that apply across all products

When uncertain which scope applies, ask the user before injecting the fragment.

**Validation**: Ensure `fragment-id` values in `include-fragment` match fragment file names exactly (case-sensitive). Warn the user if any fragment files are not injected in any policy.

### Reuse fragments to avoid duplication

When the same logic is needed in multiple policies or phases (inbound, outbound, backend), use `include-fragment` to reference a single fragment:

```xml
<outbound>
    <include-fragment fragment-id="shared-fragment" />
    <base />
</outbound>
```

### Document fragment dependencies

Fragments pass data via context variables as data contracts. Document these relationships using comments:

```xml
<fragment>
    <!-- Dependencies: fragment-a, fragment-b -->
    <!-- Requires: input-var (context variable from prior fragment) -->
    <!-- Produces: output-var (context variable for downstream fragments) -->
    
    <choose>
        <when condition="@(!context.Variables.ContainsKey("input-var"))">
            <return-response>
                <set-status code="500" reason="Internal Server Error" />
            </return-response>
        </when>
    </choose>
    
    <!-- Fragment logic -->
</fragment>
```

### Use conditional fragment injection

Conditional injection allows different fragments based on request conditions:

```xml
<inbound>
    <include-fragment fragment-id="common-fragment" />
    <choose>
        <when condition="@(context.Request.Headers.ContainsKey("X-Custom-Header"))">
            <include-fragment fragment-id="fragment-a" />
        </when>
        <otherwise>
            <include-fragment fragment-id="fragment-b" />
        </otherwise>
    </choose>
    <base />
</inbound>
```

## Recommended Fragment Patterns

### 1. Modularity

Design each fragment with a single, well-defined responsibility. Example: a `security-authentication` fragment should only contain authentication logic.

### 2. Data Sharing

Share data between fragments using context variables:

- **Data contracts**: Use context variables to pass data between sequential fragments. Each request maintains an isolated `context.Variables` dictionary for thread-safe communication.
- **Cache shared data**: When multiple fragments need the same data, use cross-request caching to reduce parsing overhead.

**Metadata Caching Pattern**: When multiple fragments need shared configuration data, use a parse-once, cache-everywhere approach:

1. **Metadata fragment**: Store shared JSON configuration in a context variable
2. **Cache fragment**: Parse JSON once on first request, store in cache using `cache-store-value`
3. **Subsequent requests**: Retrieve parsed `JObject` from cache using `cache-lookup-value`
4. **Cache invalidation**: Include a version in the cache key; change version to force refresh

```xml
<!-- Cache lookup -->
<cache-lookup-value key="config-v1.0" variable-name="cached-config" />
<choose>
    <when condition="@(!context.Variables.ContainsKey("cached-config"))">
        <!-- Parse and cache on miss -->
        <set-variable name="config" value="@(JObject.Parse(configJson))" />
        <cache-store-value key="config-v1.0" value="@(config)" duration="3600" />
    </when>
</choose>
```

### 3. Execution Behavior

- **Sequential execution**: Insert fragments in dependency order so later fragments can access variables set by earlier fragments
- **Scope division**: Place product-specific logic in product policies, API-wide logic in API policies
- **Shared fragments**: Reuse the same fragment at both product and API levels to avoid duplication

### 4. Performance Optimization

- **Stay under 32KB**: Keep fragments under the 32KB limit (includes whitespace, comments, XML markup). If approaching limit:
  - Extract lengthy values to Named Values
  - Use shorter variable names
  - Split into smaller fragments
- **Early exit patterns**: Return immediately for health checks, auth failures, or missing required variables
- **Minimize variable access**: Consolidate multiple lookups into single expressions
- **Cache parsed data**: Avoid redundant parsing with metadata caching

## Formatting Standards

### XML Structure Formatting (API and Product Policies)

API and product policy files inject policy fragments using `include-fragment`. Follow these formatting guidelines:

- Use 2 or 4 space indentation consistently within each file
- Place each XML attribute on the same line as its element when short
- Use multi-line formatting for elements with many attributes
- Keep closing tags aligned with their opening tags

```xml
<policies>
    <inbound>
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### C# Expression Formatting

**Single-statement expressions**: Use `@(expression)` for well-formed C# expression statements:

```xml
<set-variable name="user" value="@(context.Variables.GetValueOrDefault<string>("user-id", ""))" />
```

**Multi-line expressions**: Use `@{}` blocks with a return statement:

- Use consistent indentation (tabs or spaces) inside the expression
- Align code blocks logically for readability
- Keep try/catch blocks compact but readable
- Close the expression with `}" />` on the same line as the last statement when practical

```xml
<set-variable name="result" value="@{
    try {
        var input = context.Variables.GetValueOrDefault<string>("input-var", "");
        var processed = input.ToLower().Trim();
        return !String.IsNullOrEmpty(processed) ? processed : "default";
    } catch { return "error"; }
}" />
```

## Testing Policies

Policy changes cannot be unit tested directly. Validation occurs through:

1. **Terraform validation** - Ensures XML files are syntactically valid
2. **Deployment** - APIM validates policies during deployment