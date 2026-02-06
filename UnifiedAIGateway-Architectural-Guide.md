# Unified AI Gateway Design Pattern - Architectural Guide

The **Unified AI Gateway design pattern** routes requests to multiple AI services/models through a single [Azure API Management (APIM)](https://learn.microsoft.com/azure/api-management/api-management-key-concepts). It uses a universal wildcard API definition (/*) across GET, POST, PUT, and DELETE operations, routing all requests through a unified, policy-driven pipeline built with [policy fragments](https://learn.microsoft.com/azure/api-management/policy-fragments) to ensure consistent security, dynamic routing, load balancing, rate limiting, and comprehensive logging and monitoring.

The Unified AI Gateway pattern is designed to be extensible, allowing organizations to add support for additional API types, models, versions, etc. to meet their unique requirements through minimal updates to policy fragments. Each policy fragment is designed as a modular component with a single, well-defined responsibility. This modular design enables targeted customization, such as adding customized token tracking, without impacting the rest of the pipeline.

## Enterprise challenges when scaling AI services

As organizations scale generative AI adoption, they face growing complexity managing multiple AI providers, models, API formats, and rapid release cycles. Without a unified control plane, enterprises risk fragmented governance, inconsistent developer experiences, and uncontrolled AI consumption costs.

As an [AI Gateway](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities), APIM enables organizations to implement centralized AI mediation, governance, and developer access control across AI services. The Unified AI Gateway is a design pattern built using APIM's policy extensibility to create a flexible and maintainable solution for managing AI services across providers, models, and environments.

This pattern helps overcome challenges common across enterprises implementing multi-model and multi-provider AI architectures:

- **API growth and management overhead**: Using a conventional REST/SOAP API definition approach, each combination of AI provider, model, API type, and version typically results in a separate API schema definition in APIM. As AI services evolve, the number of API definitions can grow significantly, increasing management overhead.
- **Limited routing flexibility**: Each API definition is typically linked to a static backend, which prevents dynamic routing decisions based on factors like model cost, capacity, or performance (e.g., routing to gpt-4.1-mini instead of gpt-4o).

Because AI services evolve rapidly, this approach creates exponential growth in API definitions and ongoing management overhead:

**Separate APIs are typically needed for each of the following:**
  - AI service provider (e.g. Microsoft Foundry, Google Gemini)
  - API type (e.g., OpenAI, Inference, Responses)
  - Model (e.g., gpt4o, gpt4.1-mini, phi-4)

**Each AI service also supports multiple versions.** For instance, OpenAI might include:
  - 2025-01-01-preview (latest features)
  - 2024-10-21 (stable release)
  - 2024-02-01 (legacy support)

**Different request patterns may be required.** For example, Microsoft Foundry's OpenAI supports chat completion using both:
  - OpenAI v1 format (/v1/chat/completions)
  - Azure OpenAI format (/openai/deployments/{model}/chat/completions)

**Each API definition may be replicated across environments.** For example, Development, Test, and Production APIM environments.

## How to apply this pattern

The Unified AI Gateway design pattern is built using a policy-driven pipeline, constructed with policy fragments. The behavior of this pipeline — including authentication, request transformation, routing, and backend selection — is controlled by central metadata configuration settings (stored in the [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml) fragment). These settings provide the configuration that the pipeline needs to determine how requests are processed and routed across AI services. The following sections outline the core components involved.

![Unified AI Gateway Pattern](ContentImages/UnifiedAIGatewayPattern.png)

### Single wildcard API definition

Central to the pattern is a single wildcard API definition, which uses wildcard operations to route requests to multiple backend AI services. This approach minimizes API management overhead — *no* API definition changes are required for new models or APIs with only *minimal* updates to the pipeline. The pipeline consists of the following phases:

- **Inbound:** Loads configuration, authenticates the request, selects the backend, constructs the routing path, and enforces token limits.
- **Backend:** Forwards the request to the backend AI service.
- **Outbound:** Adds diagnostic headers to the response.
- **Error:** Adds diagnostic headers for error responses.

⚠️ **Caution:** Be cautious when you configure a wildcard operation. This configuration might make an API more vulnerable to certain <a href="https://learn.microsoft.com/azure/api-management/mitigate-owasp-api-threats" target="_blank">API security threats</a>. The sample includes example mitigations such as validating request paths against configured API types, reconstructing backend paths from known components, enforcing inbound authentication (API key or JWT), using managed identity for backend authentication, and emitting detailed trace logs for monitoring. However, these mitigations may not address all security concerns. Organizations should analyze risks and implement mitigations based on their unique security requirements.

### Unified authentication

The pipeline enforces consistent authentication for every request, supporting both subscription/API key and JWT validation for inbound requests, and managed identity for backend authentication. The correct authentication method is applied automatically for each AI service:

- **Subscription/API key validation:** Uses the [subscription key](https://learn.microsoft.com/azure/api-management/api-management-subscriptions#use-a-subscription-key) when the api-key header is present.
- **JWT validation:** Uses the [validate-jwt](https://learn.microsoft.com/azure/api-management/validate-jwt-policy) built-in policy when the authorization header is present and no api-key is specified.
- **Managed identity:** APIM's system identity for backend authentication via the [authentication-managed-identity](https://learn.microsoft.com/azure/api-management/authentication-managed-identity-policy) built-in policy.

### Optimized path construction

Requests are automatically transformed to simplify and streamline how API developers consume AI services. The pipeline detects the model and API type in each inbound request, then applies a series of optimizations. The central metadata configuration settings in the [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml) fragment specify API types and versions for each supported model, enabling path recognition and accurate routing. The following are examples of optimizations demonstrated in the sample - organizations should implement their optimizations based on their unique requirements:

- **Product prefix stripping**: Automatically removes product prefixes from paths (e.g., `/unifiedaigateway/...`) before backend routing
- **Backend base path construction**: Automatically prepends correct backend base paths from configuration (e.g., `/openai`, `/v1beta/openai`, `/models`)
- **Deployment path injection**: For OpenAI deployments, automatically injects `/deployments/{model}/` into the path when not present
- **API version override**: Automatically injects or replaces `api-version` query parameters with backend-compatible versions
- **Request body transformation**: Automatically injects `model` field into request body when client omits it (OpenAI)
- **Responses API CRUD routing**: Automatically constructs proper paths for GET/DELETE operations (`{base-path}/{response-id}`)
- **Example transformation**:
  - Frontend request: `POST {apim-endpoint}/deployments/gpt-4.1-mini/chat/completions`
  - Forwarded backend request: `POST {backend-endpoint}/openai/deployments/gpt-4.1-mini/chat/completions?api-version=2025-01-01-preview`

### Model/API-aware backend selection

Requests are dynamically routed to [backend services](https://learn.microsoft.com/azure/api-management/backends?tabs=portal) and [load balancing pools](https://learn.microsoft.com/azure/api-management/backends?tabs=portal#load-balanced-pool) that support specific models and API types. The central metadata configuration settings in the [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml) fragment specify which backend services and pools should be used for each model and API type. During request processing, the pipeline reads these settings and uses the [set-backend-service](https://learn.microsoft.com/azure/api-management/set-backend-service-policy) built-in policy to assign the appropriate backend service or pool for each request. This enables routing decisions based on factors such as:

- Capacity
- Cost
- Performance
- Other operational considerations

### Tiered token limiting

[Token limiting](https://learn.microsoft.com/azure/api-management/llm-token-limit-policy) is enforced at two levels to control usage. At the gateway level within APIM, the [llm-token-limit](https://learn.microsoft.com/azure/api-management/llm-token-limit-policy) built-in policy is used. This policy limits based on actual token consumption (prompt + completion tokens). Each model is assigned a tier in the [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml) fragment, with the actual token limit values hardcoded in the [token-limiter.xml](Infra/Resources/Fragments/token-limiter.xml) fragment. At the backend AI service level, rate limits are managed by the backend services themselves, according to their own settings.

### Comprehensive trace logging and monitoring

The pipeline provides robust monitoring for cost/usage tracking, capacity planning, and operational insights. APIM's built-in [trace](https://learn.microsoft.com/azure/api-management/trace-policy) policy captures source identifiers (e.g., "Token-Limiter", "Backend-Selection-Results", "Token-Usage") and operational context (user IDs, token counts, performance metrics, errors, results). All trace entries are stored in [Application Insights](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest). Key performance indicators tracked include:

- Real-time operation stats
- Token usage (by user and subscription key)
- Performance
- Circuit breaker behavior
- Token limiting
- Errors

## When to use this pattern

The Unified AI Gateway pattern is most beneficial when organizations experience growing AI service complexity. Consider using the Unified AI Gateway pattern when:

- **Multiple AI service providers**: Your organization integrates with various AI services (Microsoft Foundry, Google Gemini, etc.)
- **Frequent model/API changes**: New models/APIs need to be regularly added or existing ones updated
- **Dynamic routing needs**: Your organization requires dynamic backend selection based on capacity, cost, or performance

**When not to use this pattern**: If you expect a limited number of models/API definitions with minimal ongoing changes, following the conventional approach may be simpler to implement and maintain. The additional implementation and maintenance effort required by the Unified AI Gateway pattern should be weighed against the management overhead it is intended to reduce.

## Get started
For a complete sample implementation with component overview and step-by-step provisioning instructions, see the [README.md](README.md) quick start guide.  The remainder of this section highlights key implementation details from the sample.

### APIM backend configuration

The sample uses various configurations for backend services and load balancing pools to demonstrate routing options, with the pipeline dynamically routing requests based on model and API type requirements.  The sample also uses APIM's built-in [circuit breaker](https://learn.microsoft.com/azure/api-management/backends?tabs=portal#circuit-breaker) functionality with [load balancing pools](https://learn.microsoft.com/azure/api-management/backends?tabs=portal#load-balanced-pool) to provide resiliency across backend AI services deployed in different regions.

**Circuit breaker triggers**: All APIM backends are configured to detect failures for status codes 500-503 and 429.

**API type routing**: The pipeline detects the API type used in each request and routes it accordingly. Because the Responses API is stateful, the sample routes all Responses API requests to a single GPT-4.1-mini backend instance. Using a single backend instance ensures GET/DELETE operations succeed because the same backend service contains the initial stored context (this avoids 404/Not Found errors). However, in production, multi-region load balancing would typically be used with preferred region routing for stateful APIs.

**Model routing**: The pipeline also detects the model included in the request to determine routing:
   - **Load balancer routing**: The sample shows routing to load balancing pools that contain multi-region GPT-4.1 and GPT-4.1-mini models.
   - **Backend routing**: The pipeline detects when Phi-4 is included in the request and routes to a single backend instance. In production, multi-region load balancing would typically be used.
 
### Pipeline policies and fragments

The sample relies on a modular approach using [policy fragments](Infra/Resources/Fragments) that are injected via an [API-level policy](https://learn.microsoft.com/azure/api-management/api-management-howto-policies) defined for the [wildcard API](Infra/Resources/Schema/unifiedaigateway-wildcard-api.json). Each fragment handles a specific aspect of request processing and communicates through [context variables](https://learn.microsoft.com/azure/api-management/api-management-policy-expressions#ContextVariables). Fragment behavior is driven by central metadata configuration settings stored in the [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml) that acts as a single source of truth. These settings enable dynamic routing and processing without changing individual policies.

**Note**: Fragments using this pattern can be injected at product or API levels. This sample uses API-level injection.

### Policy structure overview

The [wildcard API policy](Infra/Resources/Policies/APIPolicies/unifiedaigateway-wildcard-api.xml) orchestrates the pipeline by injecting fragments across different processing phases and adding timing instrumentation, product validation, and processing section context:

**Inbound phase** - Request processing and routing preparation:
1. **Product policies** - Product-level authentication policies
   - [unifiedaigateway-product-subscription.xml](Infra/Resources/Policies/ProductPolicies/unifiedaigateway-product-subscription.xml)
   - [unifiedaigateway-product-jwt.xml](Infra/Resources/Policies/ProductPolicies/unifiedaigateway-product-jwt.xml)

2. **Metadata configuration caching** - Configuration loading and caching
   - [metadata-config.xml](Infra/Resources/Fragments/metadata-config.xml)
   - [central-cache-manager.xml](Infra/Resources/Fragments/central-cache-manager.xml)

3. **Request processing** - Request and route analysis
   - [request-processor.xml](Infra/Resources/Fragments/request-processor.xml)

4. **Security** - Fragment-level authentication processing
   - [security-handler.xml](Infra/Resources/Fragments/security-handler.xml)

5. **Backend selection** - Intelligent backend routing
   - [backend-selector.xml](Infra/Resources/Fragments/backend-selector.xml)

6. **Path construction** - Final URI path building
   - [path-builder.xml](Infra/Resources/Fragments/path-builder.xml)

7. **Token limiting** - Token consumption throttling and quota enforcement
   - [token-limiter.xml](Infra/Resources/Fragments/token-limiter.xml)

8. **Token logging** - Token usage metrics emission
   - [token-logger.xml](Infra/Resources/Fragments/token-logger.xml)

**Outbound phase** - Response processing and monitoring:

- [diagnostic-headers.xml](Infra/Resources/Fragments/diagnostic-headers.xml) - Diagnostic information headers

**Error phase** - Exception handling:
- [diagnostic-headers.xml](Infra/Resources/Fragments/diagnostic-headers.xml) - Diagnostic information headers

### Product policies

The pipeline uses two product policies to enable the appropriate authentication method:

- **Subscription product policy**: The [unifiedaigateway-product-subscription.xml](Infra/Resources/Policies/ProductPolicies/unifiedaigateway-product-subscription.xml) policy requires a subscription key for access. It ensures that API access requires a valid product subscription.

- **JWT product policy**: The [unifiedaigateway-product-jwt.xml](Infra/Resources/Policies/ProductPolicies/unifiedaigateway-product-jwt.xml) policy enables JWT Bearer token authentication by not requiring a subscription key. It ensures that API access requires a valid product subscription and provides proper product context for JWT validation by the `security-handler` fragment.

### Metadata configuration caching
The pipeline implements metadata configuration caching through two specialized fragments: [metadata-config](Infra/Resources/Fragments/metadata-config.xml) and [central-cache-manager](Infra/Resources/Fragments/central-cache-manager.xml). These fragments work together to optimize performance and reduce JSON parsing overhead across requests.

**Metadata config structure**

The `metadata-config` fragment loads a centralized JSON configuration containing:
- **Models**: Backend mappings, tier assignments, and API versions for each AI model.
- **API types**: Base paths, patterns, and version settings for different API endpoints.
- **Cache settings**: Cross-request caching configuration including version control and TTL.

**Caching implementation details**

The sample uses the following caching strategy:

- **Single parse operation**: Uses `JObject.Parse()` to parse the `metadata-config` once at the start of each pipeline request if the cache is empty.
- **Cross-request caching**: Uses a version-based cache key (`metadata-config-v{version}`) to store and retrieve parsed metadata sections as a `JObject` via the built-in [cache-store-value](https://learn.microsoft.com/azure/api-management/cache-store-value-policy) and [cache-lookup-value](https://learn.microsoft.com/azure/api-management/cache-lookup-value-policy) policies, enabling shared access across multiple requests.
- **Cache-first access**: Subsequent requests retrieve a parsed `JObject` directly from the cache, providing immediate access to all fragments without reparsing.

**Cache configuration options**

The `central-cache-manager` fragment behavior is controlled by the `cache-settings` section specified in the `metadata-config` fragment:

- **Version control**: Uses `config-version` as part of the cache key to enable automatic cache invalidation. When the version changes, old cached data is automatically invalidated and fresh data is parsed and cached.
- **TTL control**: Configurable time-to-live via `ttl-seconds` (default: 300 seconds) determines how long parsed configuration remains in cache before expiring.
- **Cache bypass**: The `UAIG-Config-Cache-Bypass` header allows bypassing cache entirely for testing and debugging scenarios. When set to `true`, the configuration is parsed fresh without reading from or writing to the APIM cache.

### Path transformation

The sample implements path transformation through the [request-processor](Infra/Resources/Fragments/request-processor.xml) fragment, which analyzes incoming requests to extract JSON content, validate structure, identify the API type (OpenAI, Inference, Responses, Gemini), extract model IDs from URLs or request bodies, and strip product prefixes to create clean routing paths. It also determines operation types (chat, completions, CRUD operations) for proper backend handling.

The following settings from the [metadata-config](Infra/Resources/Fragments/metadata-config.xml) fragment control this behavior:

- **Models**: The `models` settings define the valid model names/IDs and their model-specific API versions for path construction. The system uses these settings to determine which model IDs are valid from requests and choose model-specific API versions. For API version selection, the system first checks model-specific versions (`api-version` or `inference-api-version`) before falling back to api-types configuration.

- **API types**: The `api-types` settings define base paths, path patterns, and API versions for different endpoint types (OpenAI, Inference, Responses, Gemini). These settings provide default values for prefix addition and API versions, serving as fallbacks when model-specific settings are not defined. 

### Security

The sample implements authentication through the [security-handler](Infra/Resources/Fragments/security-handler.xml) fragment, which handles both API key and JWT Bearer token validation, extracts user context, and manages managed identity tokens for secure backend communication. For backend authentication, the sample uses APIM's managed identity for Microsoft Foundry AI services and an API key for Gemini. 

The `security-handler` fragment detects the authentication method automatically, validates credentials, extracts user identity information, and acquires managed identity tokens for backend authentication. It produces authentication context variables that downstream fragments use for rate limiting and monitoring decisions.

JWT authentication settings (issuer, audience, and OpenID configuration URL) are stored in APIM named values and retrieved directly within the `security-handler` fragment. This enables JWT Bearer token validation against Microsoft Entra ID.

**Important**: Secret values, like the Gemini API key, are [stored in Azure Key Vault](https://learn.microsoft.com/security/benchmark/azure/baselines/api-management-security-baseline#service-credential-and-secrets-support-integration-and-storage-in-azure-key-vault) and referenced through APIM Named Values.

### Backend selection

The sample implements intelligent backend selection through the [backend-selector](Infra/Resources/Fragments/backend-selector.xml) fragment, which dynamically routes requests to the pre-configured backend services and load balancing pools described in the [APIM backend configuration](#apim-backend-configuration) section above. This fragment determines which backend pool or service should handle each request based on the extracted model ID and API type, using settings defined in the `metadata-config`.

The following settings from the [metadata-config](Infra/Resources/Fragments/metadata-config.xml) fragment control backend selection behavior:

- **API types**: The `api-types` settings can specify a `backend` property for specialized endpoints. When an API type has an explicit backend configured, that backend is used (e.g., `responses` API type routes to `standard-responses-backend`).
- **Models**: The `models` settings specify which backend service or pool each model should use via the `backend` property. Model backends are used when the API type does not define its own backend.

The sample uses a simple heuristic: if the API type explicitly defines a backend, use it (specialized endpoint routing); otherwise, use the model's configured backend (standard routing). Heuristics should be customized based on organizational requirements.

The `backend-selector` fragment extracts model IDs from multiple sources within the request (such as URL path and body), validates them against the `metadata-config` settings, and selects the appropriate backend service. This enables dynamic routing decisions based on model requirements, load balancing needs, and backend availability.

### Path construction

The [path-builder](Infra/Resources/Fragments/path-builder.xml) fragment uses the routing variables to build the final backend URI path, adding required prefixes (like `/openai` or `/v1beta`), injecting API versions as query parameters, and transforming paths to match backend API expectations.

### Token limiting

The sample implements gateway-level token limiting through the [token-limiter](Infra/Resources/Fragments/token-limiter.xml) fragment. This fragment enforces token consumption limits using Azure API Management's [llm-token-limit](https://learn.microsoft.com/azure/api-management/llm-token-limit-policy) policy, which limits based on actual token usage. The token limiting uses dynamic key generation that creates unique counters for each user-tier combination.

**Gateway token limiting implementation**

The token limiting system operates using the following `metadata-config` values:

- **Token limit tiers**: Each model defines a `tier` property that determines its token limits:
  - `premium`: 2,000 tokens per minute, 10,000 hourly quota (e.g., gpt-4.1)
  - `standard`: 1,000 tokens per minute, 5,000 hourly quota (e.g., gpt-4.1-mini, phi-4, gemini-2.5-flash-lite)

- **Default handling**: Falls back to "standard" tier limits when model-specific tier is not defined.

**Token limiting key generation**

The fragment creates unique token limiting keys based on authentication method:

- **API key authentication**: `uaig-sub-{subscription-id}-{tier}`
- **JWT authentication**: `uaig-jwt-{user-id}-{tier}`
- **Anonymous access**: `uaig-ip-{ip-address}-{tier}`

**Configuration integration**

The token limiting uses the `tier` setting from `metadata-config` to assign each model to a tier. The actual token limit values (tokens-per-minute and token-quota) are hardcoded in the fragment because the `llm-token-limit` policy doesn't allow policy expressions for these attributes.

The fragment applies token limits using APIM's built-in [llm-token-limit](https://learn.microsoft.com/azure/api-management/llm-token-limit-policy) policy, automatically returning 429 errors when per-minute limits are exceeded (with UAIG-Retry-After header) and 403 errors when hourly quotas are exhausted. Diagnostic headers provide visibility into remaining tokens and consumption.

### Request timeout management

The sample implements dynamic request timeouts based on model configuration and streaming status. Each model defines a `timeout` property (in seconds) in `metadata-config`, and the `timeout-settings` section specifies a `streaming-multiplier` for extended streaming timeouts.

**Timeout calculation**: For non-streaming requests, the model's base timeout is used directly. For streaming requests (when `"stream": true` is present in the request body), the base timeout is multiplied by the streaming multiplier (default: 3x). For example, a model with a 120-second timeout would have a 360-second timeout for streaming requests.

The calculated timeout is applied to the [forward-request](https://learn.microsoft.com/azure/api-management/forward-request-policy) built-in policy and exposed via the `UAIG-Request-Timeout` diagnostic header.

### Token usage metrics

The sample implements token usage metrics through the [token-logger](Infra/Resources/Fragments/token-logger.xml) fragment. This fragment uses APIM's built-in [llm-emit-token-metric](https://learn.microsoft.com/azure/api-management/llm-emit-token-metric-policy) policy to emit prompt, completion, and total token counts to Application Insights.

**Metric namespaces**: Metrics are organized by API type (UAIG-OpenAI, UAIG-Inference, UAIG-Responses, UAIG-Gemini) for granular cost attribution and monitoring. Each metric includes dimensions for model ID, user ID, subscription, backend, and request paths.

## Related resources

- [Azure Gateway Guide for OpenAI and Other Language Models](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Azure OpenAI Gateway Multi-Backend](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)