# Optional Dependencies

Patterns for optional service dependencies. Add to constructor after core dependencies (ILogger, IDistributedTracing, IMeterFactory, IOptions) in alphabetical order.

## Clients/ — External HTTP API Wrappers

For services that wrap an external HTTP API, use the `Clients/` folder with a typed client pattern. This separates HTTP concerns (serialization, retries, auth headers) from business logic.

`{ExternalApi}` is the confirmed PascalCase name of one external system/client role. Gather it whenever this
capability is selected and substitute it consistently in every client, contract, serializer-context, settings,
and resilience-pipeline name. Resolve a separate value for each integration.

```
Clients/
├── I{ExternalApi}Client.cs       # Interface
├── {ExternalApi}Client.cs        # Implementation
├── {ExternalApi}Request.cs       # Integration request contract
├── {ExternalApi}Response.cs      # Integration response contract
└── {ExternalApi}JsonSerializerContext.cs
```

Add this capability as one coherent set; do not copy only the client class:

| Artifact | Required addition |
|----------|-------------------|
| `Configuration/{ServiceName}Settings.cs` | `ApiBaseUrl`, `HttpTimeout`, and `MaxRetryAttempts` |
| `appsettings.json` | Deployment-specific `ApiBaseUrl`; operational values may use documented defaults |
| `Extensions/StartupExtensions.cs` | Conditional URL/timeout validation plus typed-client and resilience registration below |
| `{ServiceName}Service.cs` | Inject `I{ExternalApi}Client`; translate integration failures into the service's explicit transient/permanent exception categories |

Merge `using System;` and `using System.ComponentModel.DataAnnotations;` into the owning Settings file for
`TimeSpan` and the range attribute.

```csharp
// Configuration/{ServiceName}Settings.cs additions
[AbsoluteHttpUrl]
public string ApiBaseUrl { get; set; } = null!;

public TimeSpan HttpTimeout { get; set; } = TimeSpan.FromSeconds(30);

[Range(0, 10)]
public int MaxRetryAttempts { get; set; } = 3;
```

```csharp
// StartupExtensions options-validation additions
.Validate(
    settings => !settings.Enabled || !string.IsNullOrWhiteSpace(settings.ApiBaseUrl),
    "ApiBaseUrl is required when the service is enabled.")
.Validate(
    settings => settings.HttpTimeout > TimeSpan.Zero,
    "HttpTimeout must be positive.")
```

Use service-specific names such as `{ExternalApi}BaseUrl` when one service has multiple external clients;
rename the settings, validators, and registration together.

```csharp
// Clients/{ExternalApi}Request.cs and Clients/{ExternalApi}Response.cs
namespace {ServiceNamespace}.Clients;

using System.Text.Json.Serialization;

public sealed record {ExternalApi}Request(
    [property: JsonPropertyName("data")] string Data);

public sealed record {ExternalApi}Response(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("result")] string Result);
```

```csharp
// Clients/I{ExternalApi}Client.cs
namespace {ServiceNamespace}.Clients;

using System.Threading;
using System.Threading.Tasks;

public interface I{ExternalApi}Client
{
    Task<{ExternalApi}Response> GetByIdAsync(string id, CancellationToken cancellationToken);
    Task<{ExternalApi}Response> CreateAsync(
        {ExternalApi}Request request,
        CancellationToken cancellationToken);
}
```

```csharp
// Clients/{ExternalApi}Client.cs
namespace {ServiceNamespace}.Clients;

using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;

public sealed class {ExternalApi}Client : I{ExternalApi}Client
{
    private readonly HttpClient _httpClient;

    public {ExternalApi}Client(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<{ExternalApi}Response> GetByIdAsync(
        string id,
        CancellationToken cancellationToken)
    {
        using var response = await _httpClient.GetAsync(
            $"/api/resource/{Uri.EscapeDataString(id)}",
            cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync(
                {ExternalApi}JsonSerializerContext.Default.{ExternalApi}Response,
                cancellationToken)
            ?? throw new InvalidDataException("The external API returned an empty response body.");
    }

    public async Task<{ExternalApi}Response> CreateAsync(
        {ExternalApi}Request request,
        CancellationToken cancellationToken)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            "/api/resource",
            request,
            {ExternalApi}JsonSerializerContext.Default.{ExternalApi}Request,
            cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync(
                {ExternalApi}JsonSerializerContext.Default.{ExternalApi}Response,
                cancellationToken)
            ?? throw new InvalidDataException("The external API returned an empty response body.");
    }
}
```

```csharp
// Clients/{ExternalApi}JsonSerializerContext.cs
namespace {ServiceNamespace}.Clients;

using System.Text.Json.Serialization;

[JsonSerializable(typeof({ExternalApi}Request))]
[JsonSerializable(typeof({ExternalApi}Response))]
internal partial class {ExternalApi}JsonSerializerContext : JsonSerializerContext
{
}
```

Registration in `Extensions/StartupExtensions.cs` using typed client with resilience:

```csharp
services.AddHttpClient<I{ExternalApi}Client, {ExternalApi}Client>((serviceProvider, client) =>
{
    var settings = serviceProvider.GetRequiredService<IOptions<{ServiceName}Settings>>().Value;
    client.BaseAddress = new Uri(settings.ApiBaseUrl, UriKind.Absolute);
    client.Timeout = Timeout.InfiniteTimeSpan;
})
.AddResilienceHandler("{ServiceName}-{ExternalApi}", static (builder, context) =>
{
    var settings = context.ServiceProvider.GetRequiredService<IOptions<{ServiceName}Settings>>().Value;

    var retryOptions = new HttpRetryStrategyOptions
    {
        BackoffType = DelayBackoffType.Exponential,
        Delay = TimeSpan.FromSeconds(1),
        MaxRetryAttempts = settings.MaxRetryAttempts,
        UseJitter = true,
    };
    retryOptions.DisableForUnsafeHttpMethods();
    builder.AddRetry(retryOptions);
    builder.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions());
    builder.AddTimeout(settings.HttpTimeout);
});
```

Required registration usings: `System`, `System.Threading`, `Microsoft.Extensions.DependencyInjection`,
`Microsoft.Extensions.Http.Resilience`, `Microsoft.Extensions.Options`, and `Polly`.

`{ServiceName}Service.cs` then injects `I{ExternalApi}Client` directly (not `IHttpClientFactory`).

> **When to use Clients/ vs IHttpClientFactory**: Use `Clients/` when wrapping an external API with multiple methods, response mapping, and error translation. Use `IHttpClientFactory` directly (below) for simple one-off HTTP calls.

## IHttpClientFactory

For simple HTTP calls that don't warrant a full client wrapper.

**Important**: Resilience policies (retry, circuit breaker, timeout) MUST be configured in the service's own `Extensions/StartupExtensions.cs`, colocated with the HTTP client registration. Do NOT add resilience at the host level (`ProgramExtensions.cs` / `ConfigureHttpClientDefaults`) — it stacks rather than overrides, causing double retries and conflicting timeouts.

Add the named client identity to `Constants.cs`:

```csharp
public const string HttpClientName = "{ServiceName}";
```

Merge `using System;` and `using System.ComponentModel.DataAnnotations;` into Settings for `TimeSpan` and
`MaxRetryAttempts`.

```csharp
// Field
private readonly IHttpClientFactory _httpClientFactory;

// Constructor parameter
IHttpClientFactory httpClientFactory

// Constructor body
_httpClientFactory = httpClientFactory;

// Service method usage
var httpClient = _httpClientFactory.CreateClient(Constants.HttpClientName);
using var response = await httpClient.PostAsync(url, content, cancellationToken);
response.EnsureSuccessStatusCode();

// Settings additions (reuse them if the typed-client capability already added them)
public TimeSpan HttpTimeout { get; set; } = TimeSpan.FromSeconds(30);

[Range(0, 10)]
public int MaxRetryAttempts { get; set; } = 3;

// StartupExtensions - register named client with resilience pipeline
services.AddHttpClient(Constants.HttpClientName, client =>
    {
        client.Timeout = Timeout.InfiniteTimeSpan;
    })
    .AddResilienceHandler("{ServiceName}Pipeline", static (builder, context) =>
    {
        var settings = context.ServiceProvider.GetRequiredService<IOptions<{ServiceName}Settings>>().Value;

        var retryOptions = new HttpRetryStrategyOptions
        {
            BackoffType = DelayBackoffType.Exponential,
            Delay = TimeSpan.FromSeconds(1),
            MaxRetryAttempts = settings.MaxRetryAttempts,
            UseJitter = true
        };
        retryOptions.DisableForUnsafeHttpMethods();
        builder.AddRetry(retryOptions);

        builder.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
        {
            SamplingDuration = TimeSpan.FromSeconds(90),
            FailureRatio = 0.2,
            MinimumThroughput = 100
        });

        builder.AddTimeout(settings.HttpTimeout);
    });

// Required usings in StartupExtensions
// using System;
// using System.ComponentModel.DataAnnotations;
// using System.Threading;
// using Microsoft.Extensions.Http.Resilience;
// using Polly;
```

Add the same positive `HttpTimeout` options validator shown in the typed-client capability. The resilience
options retain the framework's transient HTTP/transport predicate; do not replace it with a result-only
predicate that drops timeouts or `HttpRequestException`. Unsafe methods are excluded from automatic retry.
Enable retry for POST/PATCH only after the remote operation has a confirmed idempotency-key contract and the
client sends a stable key on every attempt; place that opt-in in a separately named pipeline.

## HybridCache

```csharp
// Field
private readonly HybridCache _hybridCache;

// Constructor parameter
HybridCache hybridCache

// Constructor body
_hybridCache = hybridCache;

// StartupExtensions - add to required services
typeof(HybridCache)

// Usage
var result = await _hybridCache.GetOrCreateAsync(
    cacheKey,
    async token => await FetchDataAsync(token),
    cancellationToken: cancellationToken);
```

## IDistributedCache

```csharp
// Field
private readonly IDistributedCache _distributedCache;

// Constructor parameter
IDistributedCache distributedCache

// Constructor body
_distributedCache = distributedCache;

// StartupExtensions - add to required services
typeof(IDistributedCache)

// Usage
var cached = await _distributedCache.GetStringAsync(key, cancellationToken);
await _distributedCache.SetStringAsync(key, value, options, cancellationToken);
```

## IDistributedLock

[Ruya.Services.DistributedLock](https://github.com/cilerler/ruya/blob/main/src/Ruya.Services.DistributedLock/README.md) is the reference implementation for the callback-based API below. The callback receives a token that is cancelled if heartbeat renewal loses ownership; generated code must pass that token through every operation in the critical section.

```csharp
// Field
private readonly IDistributedLock _distributedLock;

// Constructor parameter
IDistributedLock distributedLock

// Constructor body
_distributedLock = distributedLock;

// StartupExtensions - add to required services
typeof(IDistributedLock)

// Usage
LockResult lockResult = await _distributedLock.AcquireAndExecuteWithLockAsync(
    lockCancellationToken => ProcessResourceAsync(resourceId, lockCancellationToken),
    $"lock:{resourceId}",
    lockValue: null,
    options: new LockOptions
    {
        CustomExpiry = TimeSpan.FromSeconds(30),
        HeartbeatInterval = TimeSpan.FromSeconds(10)
    },
    cancellationToken);

if (!lockResult.IsSuccess)
{
    // Apply the service's confirmed retry or failure policy.
}
```

## ICloudStorageFactory

[Ruya.Services.CloudStorage](https://github.com/cilerler/ruya/blob/main/src/Ruya.Services.CloudStorage.Abstractions/README.md) is the reference implementation for the provider-keyed API below.

```csharp
// Field
private readonly ICloudStorageFactory _cloudStorageFactory;

// Constructor parameter
ICloudStorageFactory cloudStorageFactory

// Constructor body
_cloudStorageFactory = cloudStorageFactory;

// StartupExtensions - add to required services
typeof(ICloudStorageFactory)

// Usage
ICloudFileService storage = _cloudStorageFactory.GetService(_settings.StorageProvider);
CloudFileMetadata metadata = await storage.UploadStreamAsync(
    bucketName,
    stream,
    path,
    contentType,
    cancellationToken);
```

## IMessageQueueFactory

[Ruya.Services.MessageQueue](https://github.com/cilerler/ruya/blob/main/src/Ruya.Services.MessageQueue/README.md) is the reference implementation for the API shape below.

Selecting a long-lived subscriber automatically selects `IMessageQueueFactory`. For each `{EventName}`, use the producer-owned contract and generate the following capability-owned additions instead of hardcoding provider or topic names:

| Artifact | Required addition |
|----------|-------------------|
| Event contract | If this service owns and publishes a new event, place its contract at the owning abstraction boundary from [`modular-polylith.md`](modular-polylith.md#cross-module-communication), give serialized members stable `JsonPropertyName` values, and include it in that boundary's source-generated `JsonSerializerContext`. If this service only consumes the event, reference the producer-owned contract and context; never generate a local copy. |
| `Configuration/{ServiceName}Settings.cs` | `public string MessageQueueProviderName { get; set; } = null!;` and `public string {EventName}TopicName { get; set; } = null!;`, validated conditionally when the service is enabled |
| `appsettings.json` | `MessageQueueProviderName` and `{EventName}TopicName` values under the service configuration section |
| Resolved `I{ServiceName}` contract (default `Contracts/I{ServiceName}.cs`) | Merge `using {ProducerContractNamespace};` and replace the neutral placeholder operation with `Task ProcessAsync({EventName} message, CancellationToken cancellationToken);` when the event is consumed. If the interface lives at a broader boundary, update its resolved owning file rather than creating a local duplicate. |

`{EventName}` means the exact unqualified CLR type name, including its full semantic name and suffix
(for example, `IngredientQuoteRequestedEvent`, not `QuoteRequest` and not a namespace-qualified name).
When one service consumes multiple event types,
keep one `{EventName}TopicName` setting per contract and overload `ProcessAsync` by message type; do not
invent abbreviated topic-property or operation names.

```csharp
// Resolved I{ServiceName} contract additions; default file: Contracts/I{ServiceName}.cs
using {ProducerContractNamespace};

Task ProcessAsync({EventName} message, CancellationToken cancellationToken);
```

These settings follow the domain-value rules in [`standard-service.md`](standard-service.md#configurationservicenamesettingscs); their deployment-specific values have no source-code defaults. Add options validation that requires both nonblank values only when `Enabled` is true, so a disabled service does not fail startup for unused broker configuration.

Confirm that the selected queue serializer is configured with the producer-owned source-generated context.
If the implementation cannot accept that context, stop and surface the serialization capability gap instead
of silently using reflection.

```csharp
.Validate(
    settings => !settings.Enabled ||
        (!string.IsNullOrWhiteSpace(settings.MessageQueueProviderName) &&
         !string.IsNullOrWhiteSpace(settings.{EventName}TopicName)),
    "Message queue provider and topic are required when the service is enabled.")
```

```csharp
// Field
private readonly IMessageQueueFactory _messageQueueFactory;

// Constructor parameter
IMessageQueueFactory messageQueueFactory

// Constructor body
_messageQueueFactory = messageQueueFactory;

// StartupExtensions - add to required services
typeof(IMessageQueueFactory)

// Publish usage
var queue = await _messageQueueFactory.CreateQueueAsync(
    _settings.MessageQueueProviderName,
    cancellationToken);
await queue.PublishAsync(
    _settings.{EventName}TopicName,
    message,
    cancellationToken: cancellationToken);
```

The factory owns the named queue instance. Code that calls `CreateQueueAsync` does not dispose that shared queue.

### Durable Outbox routing and identity

When the service publishes through a durable Outbox, the same capability settings still own routing:

- Stamp `_settings.MessageQueueProviderName` on every persisted envelope using the Outbox adapter's
  dispatcher/provider override. Do not rely on a host-global fallback when different services may use
  different providers. With Ruya, call `IOutboxPublisher.EnqueueSourceGeneratedAsync` with the exact
  producer-owned `JsonTypeInfo` selected above and pass
  `new OutboxPublishOverrides { DispatcherName = _settings.MessageQueueProviderName }`.
- Publish to `_settings.{EventName}TopicName`; do not introduce a second topic constant for the Outbox path.
- Treat the persisted Outbox envelope ID as the end-to-end message ID. Every dispatch attempt, including
  a redispatch after broker publish succeeds but marking the Outbox row fails, must publish that same ID.
  The adapter and selected provider must support and honor a caller-supplied message ID rather than
  generating a new transport ID for each attempt.
- Preserve correlation, causation, source, and custom headers when reconstructing a persisted envelope.
- If the Outbox adapter rehydrates the persisted JSON before transport publish, it must use the same
  producer-owned source-generated metadata used at enqueue. It must not reinterpret the application contract
  with reflection or unrelated default JSON options. Verify this with a producer context whose naming policy or
  converter differs from the transport default.

```csharp
await _outboxPublisher.EnqueueSourceGeneratedAsync(
    _settings.{EventName}TopicName,
    message,
    {ProducerJsonSerializerContext}.Default.{EventName},
    new OutboxPublishOverrides
    {
        DispatcherName = _settings.MessageQueueProviderName,
    },
    cancellationToken);
```

`{ProducerJsonSerializerContext}` is the context owned by the event's producer boundary. Do not generate a
consumer-local context or fall back to the reflection-based `EnqueueAsync` overload for application events.

For Ruya's MessageQueue adapter, `OutboxPublishOverrides.DispatcherName` selects the named provider and
`PublishOptions.MessageId` carries the persisted reliable-envelope ID. A single `PublishOptions.MessageId`
must not be reused for a batch containing multiple logical messages.

### Long-lived subscriptions

A broker subscriber is a thin, event-driven `BackgroundService` adapter. Do not derive it from `WorkerBackgroundService`: a subscription remains open and the broker owns delivery timing, concurrency, and redelivery rather than the cron/polling loop.

`{ProducerContractNamespace}` is the namespace of the producer-owned event at the confirmed abstractions
boundary. Substitute it; never copy the event into `{ServiceNamespace}` merely to simplify a `using`.

```csharp
namespace {ServiceNamespace};

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Ruya.Services.MessageQueue;
using {ProducerContractNamespace};
using {ServiceNamespace}.Configuration;
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public sealed class {EventName}Subscriber : BackgroundService
{
    private static readonly EventId SubscriberDisabled = new(1000, nameof(SubscriberDisabled));
    private static readonly EventId SubscriptionStarting = new(1001, nameof(SubscriptionStarting));
    private static readonly EventId SubscriptionStopping = new(1002, nameof(SubscriptionStopping));
    private static readonly EventId InvalidMessageRejected = new(1003, nameof(InvalidMessageRejected));
    private static readonly EventId TransientFailureRetrying = new(1004, nameof(TransientFailureRetrying));

    private readonly ILogger<{EventName}Subscriber> _logger;
    private readonly {ServiceName}Settings _settings;
    private readonly IMessageQueueFactory _messageQueueFactory;
    private readonly IServiceScopeFactory _scopeFactory;

    public {EventName}Subscriber(
        ILogger<{EventName}Subscriber> logger,
        IOptions<{ServiceName}Settings> options,
        IMessageQueueFactory messageQueueFactory,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _settings = options.Value;
        _messageQueueFactory = messageQueueFactory;
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation(
                SubscriberDisabled,
                "Subscriber {SubscriberName} is disabled.",
                nameof({EventName}Subscriber));
            return;
        }

        var queue = await _messageQueueFactory.CreateQueueAsync(
            _settings.MessageQueueProviderName,
            stoppingToken);

        _logger.LogInformation(
            SubscriptionStarting,
            "Subscribing to {Topic} through {ProviderName}.",
            _settings.{EventName}TopicName,
            _settings.MessageQueueProviderName);

        await using var subscription = await queue.SubscribeAsync<{EventName}>(
            _settings.{EventName}TopicName,
            HandleAsync,
            new SubscribeOptions
            {
                MaxDeliveryCount = {MaximumDeliveryCount},
                RequeueOnException = false,
                RetryPolicy = new RetryPolicy
                {
                    MaxRetryAttempts = {MaximumRetryAttempts},
                    InitialDelay = TimeSpan.FromSeconds({InitialRetryDelaySeconds}),
                    MaxDelay = TimeSpan.FromSeconds({MaximumRetryDelaySeconds}),
                    BackoffMultiplier = 2,
                    UseExponentialBackoff = true,
                    UseJitter = true,
                },
            },
            cancellationToken: stoppingToken);

        try
        {
            await Task.Delay(Timeout.InfiniteTimeSpan, stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation(
                SubscriptionStopping,
                "Stopping subscription to {Topic}.",
                _settings.{EventName}TopicName);
        }
    }

    private async Task<MessageResult> HandleAsync(MessageContext<{EventName}> context)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var service = scope.ServiceProvider.GetRequiredService<I{ServiceName}>();

        try
        {
            await service.ProcessAsync(context.Envelope.Payload, context.CancellationToken);
            return MessageResult.Success();
        }
        catch (OperationCanceledException) when (context.CancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch ({InvalidMessageException} ex)
        {
            _logger.LogWarning(
                InvalidMessageRejected,
                ex,
                "Rejecting invalid {EventName}.",
                nameof({EventName}));
            return MessageResult.Reject("Invalid message.");
        }
        catch ({TransientException} ex)
        {
            _logger.LogWarning(
                TransientFailureRetrying,
                ex,
                "Transient failure while processing {EventName}.",
                nameof({EventName}));
            return MessageResult.Retry("Transient processing failure.");
        }
    }
}
```

Register the adapter with `services.AddHostedService<{EventName}Subscriber>()` inside the service's `StartupExtensions`. The subscriber owns and asynchronously disposes the returned `IMessageSubscription`; the cancellation token alone does not replace that ownership. Resolve `I{ServiceName}` from a new scope per delivery so scoped registrations are safe; a singleton registration still resolves to its one shared instance. Keep all business logic in `I{ServiceName}`.

Before generating the adapter, gather the delivery policy: which non-overlapping concrete exceptions are transient, which indicate an invalid/permanent message, and what the selected broker does with retry and reject results. Replace `{TransientException}` and `{InvalidMessageException}` with those concrete types. Validate message identity and routing invariants before database mutation or an irreversible external call. Unknown exceptions remain unhandled and propagate to the queue implementation; cancellation requested by the delivery context also propagates. There is no universal retry/reject default.

An explicit `Retry` policy needs a finite delivery budget and nonzero bounded exponential backoff with jitter;
replace every delivery-policy placeholder above with the gathered concrete values and do not generate a hot,
unbounded requeue loop. Keep `RequeueOnException = false` unless a separately identified exception path is
both transient and safe to replay; concrete transient exceptions returned as `MessageResult.Retry` do not need
that switch. When host shutdown requests the delivery token, the queue implementation must leave
unfinished work eligible for another consumer (normally by leaving it unsettled or requeueing it). Shutdown
cancellation is not poison and must not be converted into `Reject` or sent to a DLQ.

Assume at-least-once delivery unless the selected broker contract proves otherwise. Make `I{ServiceName}` idempotent or use the selected implementation's inbox/deduplication facility; [Ruya reliable messaging](https://github.com/cilerler/ruya#reliable-messaging) is the reference implementation.

An inbox integration is conformant only when it provides an **atomic execution callback** and an adapter-owned delivery scope. Resolve `I{ServiceName}` from the service provider supplied by that callback; do not create a nested handler scope. The inbox claim, business-state mutation, and processed transition must commit in one transaction on `Success`. `Retry` and unhandled exceptions must roll back both the claim and mutation so a redelivery remains eligible to invoke the handler. Define whether `Reject` commits a terminal inbox record or rolls back for later DLQ replay. If the selected implementation cannot prove these semantics, stop generation and surface the capability gap instead of composing low-level claim/mark calls around the business handler.

The atomic work callback may run more than once because of delivery retry or the database execution strategy.
Keep it transaction-bound. Do not emit business counters, logs, notifications, or other external effects that
claim a committed state transition from inside that callback: those effects cannot roll back. Use the selected
implementation's post-commit observer for best-effort telemetry/logging, or a transactional Outbox for a
durable external effect. The observer runs only after the implementation reports a newly `Processed` commit;
it does not run for `Retry`, `Reject`, exception, or an already-processed duplicate. Transport attempt telemetry
remains owned by the queue implementation.

Follow the observability model's [message-consumer ownership rules](../../observability/SKILL.md#message-consumer-dashboard). If application code must create the processing span because the selected implementation does not, use [`ActivityKind.Consumer`](../../observability/SKILL.md#activity-kinds); do not emit a duplicate consumer span.

Required verification for a generated subscriber:

- A disabled service does not create a queue or open a subscription.
- Host cancellation exits `ExecuteAsync` and asynchronously disposes the live subscription handle.
- Each delivery resolves the service from a fresh scope and propagates the delivery cancellation token.
- Success, retry, reject, and unhandled outcomes follow the selected delivery policy.
- Retry uses the configured finite delivery budget and bounded exponential backoff with jitter; host cancellation does not dead-letter the in-flight message.
- Duplicate delivery does not repeat a committed business mutation.
- Concurrent delivery of the same message ID through independent scopes/contexts invokes one committed handler path.
- Redispatching the same persisted Outbox envelope preserves its message ID, provider selection, topic, and headers; an Inbox-protected handler still commits once.
- A non-default `MessageQueueProviderName` routes both the Outbox dispatcher and every subscriber without relying on the global fallback.
- With an inbox selected, a handler that mutates state and then returns `Retry` or throws leaves neither the mutation nor a committed claim; redelivery invokes the handler again.
- With an inbox selected, a successful delivery commits the business mutation and `Processed` claim together, and a later duplicate skips the handler.
- Business telemetry that describes committed work is observed once after that commit, not once per retried atomic callback.

## DbContext (Direct)

Resolve the persistence identifiers from the selected data model before using this fragment:
`{DbContextName}` is the exact PascalCase `DbContext` type, `{DbSetName}` is its exact PascalCase entity-set
property, and `{EntityName}` is the exact PascalCase entity type. Substitute every token; do not generate
generic `My*` types or members.

First resolve persistence ownership:

- Use capability-local persistence when the context and model belong to only this service. Keep those
  implementation details within the capability and do not create application-wide projects for them.
- Select and reference the optional shared topology only through
  [`Canonical shared-persistence project placement`](../../solution-structure/SKILL.md#canonical-shared-persistence-project-placement).

A service consuming the shared context owns its queries, mutations, and business decisions in
`{ServiceName}Service`; Minimal API endpoints and OData controllers never inject the `DbContext` directly.
The deployable runner composes the structure-selected runtime persistence registration.

```csharp
// Field
private readonly {DbContextName} _dbContext;

// Constructor parameter
{DbContextName} dbContext

// Constructor body
_dbContext = dbContext;

// Service lifetime: Scoped (required for DbContext)

// Usage
var entities = await _dbContext.{DbSetName}
    .Where(e => e.IsActive)
    .ToListAsync(cancellationToken);
```

When OData exposes the shared model, the Data project may own the EDM contribution for shared entity sets and
concurrency metadata. The deployable runner only composes that contribution with selected module/service EDM
contributions; see [`api-patterns.md`](api-patterns.md#edm-ownership-and-composition). This does not allow an
OData controller to bypass `I{ServiceName}` and query or mutate the context directly.

## Repository/UoW Pattern

```csharp
// Field
private readonly IUnitOfWork _unitOfWork;

// Constructor parameter
IUnitOfWork unitOfWork

// Constructor body
_unitOfWork = unitOfWork;

// StartupExtensions - add to required services
typeof(IUnitOfWork)

// Service lifetime: Scoped

// Usage
var repository = _unitOfWork.GetRepository<{EntityName}>();
var entities = await repository.GetAllAsync(cancellationToken);
await _unitOfWork.SaveChangesAsync(cancellationToken);
```

## Combined Example

Service with multiple optional dependencies. This is a constructor-composition fragment to merge into the
full `{ServiceName}Service.cs` from `standard-service.md`; it is not a standalone file and does not replace
that file's namespace, imports, operations, or observability code:

```csharp
public class {ServiceName}Service : I{ServiceName}
{
    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;
    
    // Optional (alphabetical)
    private readonly IDistributedCache _distributedCache;
    private readonly HttpClient _httpClient;
    private readonly HybridCache _hybridCache;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options,
        // Optional (alphabetical)
        IDistributedCache distributedCache,
        IHttpClientFactory httpClientFactory,
        HybridCache hybridCache)
    {
        _logger = logger;
        _tracer = distributedTracing;
        _meter = meterFactory.Create(new MeterOptions(Startup.AssemblyName)
        {
            Version = Startup.AssemblyVersion,
            Tags = new TagList
            {
                { "code.namespace", GetType().Namespace },
                { "code.class", GetType().Name }
            }
        });
        _settings = options.Value;
        
        _distributedCache = distributedCache;
        _httpClient = httpClientFactory.CreateClient(Constants.HttpClientName);
        _hybridCache = hybridCache;
    }
}
```
