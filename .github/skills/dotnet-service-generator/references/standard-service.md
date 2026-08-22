# Standard Service Pattern

## File Structure

The canonical service path and folder layout are defined once in [`solution-structure`](../../solution-structure/SKILL.md#net-solution-folder-structure). This reference owns service-root file names plus the code shape and relationships inside generated files. Generate only the capability-specific artifacts selected for the service; folders with no content do not exist.

## Default service-internal path: Contracts/I{ServiceName}.cs

> **Placement rule**: `I{ServiceName}.cs` defaults to service-internal `Contracts/`. If it crosses a
> boundary, place it at the producer boundary selected by the
> [generator contract-routing table](../SKILL.md#create-when-needed)—service folder, component folder,
> sibling module abstractions project, sibling standalone-service abstractions project, or app-wide
> abstractions project. A contract consumed by another module never remains inside the implementation
> project's service-level `Abstractions/` folder.

```csharp
namespace {ServiceContractNamespace};

using System.Threading;
using System.Threading.Tasks;

public interface I{ServiceName}
{
    Task DoWorkAsync(CancellationToken cancellationToken);
}
```

`DoWorkAsync` is the neutral placeholder operation. Replace it with the service's real business operations during generation; capability references such as [`background-service.md`](background-service.md) and [`dependencies.md`](dependencies.md) define their required signatures. Do not retain an unused placeholder member.

## Default service-boundary path: Abstractions/Requests/Process{ServiceName}Request.cs

Every contract path heading in this section is a default service-boundary path, not a fixed destination.
Place the file under the selected producer boundary's matching role folder (`Requests`, `Responses`, or
`Events`) and use the resolved namespace token. When the confirmed boundary changes, move the declaration,
its contract-owned serialization context, and their namespaces together; do not leave a duplicate under
`{ServiceRoot}/Abstractions`.

```csharp
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public record Process{ServiceName}Request(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("data")] string Data);
```

## Default service-boundary path: Abstractions/Responses/{ServiceName}Response.cs

```csharp
namespace {ResponseContractNamespace};

using System;
using System.Text.Json.Serialization;

public record {ServiceName}Response(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("result")] string Result,
    [property: JsonPropertyName("processedAt")] DateTimeOffset ProcessedAt);
```

## Default service-boundary path: Abstractions/Events/{ServiceName}CompletedEvent.cs

```csharp
namespace {EventContractNamespace};

using System;
using System.Text.Json.Serialization;

public record {ServiceName}CompletedEvent(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("completedAt")] DateTimeOffset CompletedAt);
```

Every contract serialized by a selected System.Text.Json transport uses explicit JSON field names and is
included in at least one source-generated `JsonSerializerContext`. Adapter-specific exceptions follow
[`OData serialization`](api-patterns.md#odata-serialization). Context ownership for a selected System.Text.Json
branch follows its purpose:

- A reusable producer-owned context belongs at the same selected contract boundary as the contracts it
  describes. Keep it in that boundary's project or folder, under the nearest common namespace that does not
  introduce a reference to a narrower boundary. When those contracts move, move the context and update its
  namespace and project references with them.
- A consumer adapter may own an additional context for its protocol-specific serialization policy. The HTTP
  context and registration in [`api-patterns.md`](api-patterns.md#serializationservicenamejsonserializercontextcs)
  are service-owned adapter artifacts: they remain under `{ServiceRoot}/Serialization` and import the resolved
  request and response namespaces even when the DTO declarations live in another contract project.
- A selected message transport uses the producer-owned event context. If it cannot accept that
  source-generated resolver, surface the capability gap instead of silently falling back to reflection.

## Constants.cs

```csharp
namespace {ServiceNamespace};

public static class Constants
{
    public const string DefaultValue = "default";
    
    public static class Metrics
    {
        public const string ActiveRequests = "app_{ServiceSnakeName}_active_requests";
        public const string OperationTotal = "app_{ServiceSnakeName}_operation_total";
        public const string OperationDuration = "app_{ServiceSnakeName}_operation_duration_seconds";
    }
}
```

## Configuration/{ServiceName}Settings.cs

> **Rules for default values in Settings classes:**
>
> - **Never** set hardcoded defaults for properties of type `string`, `DateTime`, or `DateTimeOffset`. These are
>   **domain values** (URLs, hostnames, credentials, queue/topic/vhost/exchange names, resource names, paths,
>   header names, API keys, schema names, timestamps). Non-secret values belong in configuration providers such
>   as `appsettings.json`; credential-bearing values follow the Development-only rule below. Declare strings with
>   `= null!;` and validate them, or make values nullable when the missing state is a valid runtime scenario the
>   code explicitly handles.
> - **Feature-gated exception:** when a domain value is required only while `Enabled` is true, do not use unconditional `[Required]`. Keep `= null!;` and add an options validator that accepts the disabled state and requires a nonblank value in the enabled state. Disabled services must not fail startup for unused provider configuration.
> - **OK** to set defaults for **operational** properties of type `TimeSpan`, `int`, `long`, `byte`, `double`, `decimal`, `float`, `bool`, or `enum` — timeouts, retry counts, batch sizes, polling intervals, feature toggles, log levels. These are tuning knobs with sensible cross-environment defaults, not values that change per deployment.
> - **Exception for strings/timestamps:** a default is acceptable *only* if the value is a genuine universal constant that is not environment-specific (e.g. a format string used for serialization) — in which case prefer declaring it as a `const` rather than a property default when possible.
> - **Classify connection values by semantics, not URI syntax:** bind a credential-free URL used only as an
>   endpoint directly to a clearly named Settings property such as `ApiBaseUrl`. A provider connection URI, or
>   any value expected to carry credentials or other connection secrets, remains a connection string even when it
>   uses HTTP or HTTPS; never move it into an ordinary endpoint property such as `ManagementEndpoint`.
> - **Provider connections use descriptive `*ConnectionStringKey` indirection:** the Settings property holds
>   only the catalog key, never the resolved connection value. Keep the lookup in the provider's typed settings
>   section and name it by role, such as `RabbitMq:ManagementConnectionStringKey`; do not flatten the resolved
>   value or a duplicate provider key into unrelated service settings. Store the actual value under the top-level
>   `ConnectionStrings` section and resolve it at use-site with
>   `IConfiguration.GetConnectionString(settings.ManagementConnectionStringKey)`. While the capability
>   is enabled, validate that the key is nonblank, that it resolves to a configured value, and that the resolved
>   value has any provider-required shape. Validation messages and logs may identify the property or catalog key,
>   but must never include the resolved value or embedded credentials.
> - **Credential-bearing values are allowed only in `appsettings.Development.json`:** checked-in
>   local-development defaults use the repository's canonical provider credentials. For RabbitMQ, use
>   `useradmin/passwordadmin`; never fall back to RabbitMQ's `guest` account. Do not add a `null`, empty, or
>   placeholder connection-string entry to base `appsettings.json`. Every non-development environment creates
>   the value through secrets using Aspire secret parameters, the corresponding connection-string environment
>   variable such as `ConnectionStrings__RabbitMqManagement`, or the deployed secret/vault configuration
>   provider. Treat the Development pair as a known, disposable local default; never reuse it in a shared or
>   deployed environment, and do not place a credential-bearing value in any other checked-in settings file.

The base Settings file has no namespace imports. When `ApiBaseUrl` and `[AbsoluteHttpUrl]` are selected,
merge `using {ServiceNamespace}.Validators;` together with that property; omit the import when the validator
capability is absent.

```csharp
namespace {ServiceNamespace}.Configuration;

public class {ServiceName}Settings
{
    public const string ConfigurationSectionName = nameof({ServiceName});
    public static readonly string FeatureFlag = ConfigurationSectionName;
    
    public bool Enabled { get; internal set; }
    
    // Include only when a direct HTTP endpoint is selected.
    [AbsoluteHttpUrl]
    public string ApiBaseUrl { get; set; } = null!;
}
```

Include only the properties selected by the service's capabilities, together with their matching startup validators.

When RabbitMQ management access is selected, keep its lookup key in the provider-specific settings object:

```csharp
namespace {ServiceNamespace}.Configuration;

public sealed class RabbitMqSettings
{
    public const string ConfigurationSectionName = "RabbitMq";

    public string ManagementConnectionStringKey { get; set; } = null!;
}
```

Keep only the descriptive lookup key in base `appsettings.json`; do not declare the referenced connection-string
entry until a configuration source has a value to provide:

```json
{
  "RabbitMq": {
    "ManagementConnectionStringKey": "RabbitMqManagement"
  }
}
```

Place the canonical local-development fallback only in `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "RabbitMqManagement": "http://useradmin:passwordadmin@rabbitmq:15672"
  }
}
```

Every non-development environment supplies the value through Aspire secret parameters,
`ConnectionStrings__RabbitMqManagement`, or the deployed secret/vault provider. Do not substitute RabbitMQ's
`guest` account as another default.

## Validators/AbsoluteHttpUrlAttribute.cs

Custom validation attributes for Settings properties:

```csharp
namespace {ServiceNamespace}.Validators;

using System;
using System.ComponentModel.DataAnnotations;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
public sealed class AbsoluteHttpUrlAttribute : ValidationAttribute
{
    public AbsoluteHttpUrlAttribute()
        : base("The field {0} must be an absolute HTTP or HTTPS URL.")
    {
    }

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is null || value is string text && string.IsNullOrWhiteSpace(text))
        {
            return ValidationResult.Success;
        }

        if (value is string stringValue &&
            Uri.TryCreate(stringValue, UriKind.Absolute, out var uri) &&
            uri.Scheme is Uri.UriSchemeHttp or Uri.UriSchemeHttps)
        {
            return ValidationResult.Success;
        }

        var errorMessage = FormatErrorMessage(validationContext.DisplayName);
        return new ValidationResult(errorMessage, [validationContext.MemberName!]);
    }
}
```

Common validators for Settings:
- `[AbsoluteHttpUrl]` - Must be an absolute HTTP or HTTPS URL
- `[ScheduleValidation]` - Must be valid cron expression

Do not apply a connection-string parser attribute to a `*ConnectionStringKey` property. Perform any
provider-specific parsing against the value resolved from `IConfiguration`, and do not echo that value in a
validation result, exception, or log message.

## Models/{ServiceName}Item.cs

Internal entities and domain objects owned by this service. Public Minimal API/message DTOs belong at their
producer-owned `Abstractions/` boundary. An OData entity comes from the selected EDM owner; when the optional
shared persistence topology is selected, that may be `{Organization}.{Product}.Models`, never this
service-local folder merely because the controller is here.

```csharp
namespace {ServiceNamespace}.Models;

using System;

public record {ServiceName}Item
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
}
```

Use one exception type per file.

## Exceptions/{ServiceName}Exception.cs

```csharp
namespace {ServiceNamespace}.Exceptions;

using System;

public class {ServiceName}Exception : Exception
{
    public string? ErrorCode { get; }

    public {ServiceName}Exception(string message, string? errorCode = null) 
        : base(message)
    {
        ErrorCode = errorCode;
    }

    public {ServiceName}Exception(string message, Exception innerException, string? errorCode = null) 
        : base(message, innerException)
    {
        ErrorCode = errorCode;
    }
}
```

## Exceptions/{ServiceName}TransientException.cs

Use this concrete type only for failures the selected retry policy has classified as transient.

```csharp
namespace {ServiceNamespace}.Exceptions;

using System;

public class {ServiceName}TransientException : {ServiceName}Exception
{
    public {ServiceName}TransientException(string message)
        : base(message, "TRANSIENT_ERROR")
    {
    }

    public {ServiceName}TransientException(string message, Exception innerException)
        : base(message, innerException, "TRANSIENT_ERROR")
    {
    }
}
```

## Exceptions/{ServiceName}NotFoundException.cs

```csharp
namespace {ServiceNamespace}.Exceptions;

public class {ServiceName}NotFoundException : {ServiceName}Exception
{
    public {ServiceName}NotFoundException(string id) 
        : base($"Resource '{id}' not found.", "NOT_FOUND")
    {
    }
}
```

## Exceptions/{ServiceName}ValidationException.cs

```csharp
namespace {ServiceNamespace}.Exceptions;

using System.Collections.Generic;
using System.Linq;

public class {ServiceName}ValidationException : {ServiceName}Exception
{
    public IReadOnlyList<string> Errors { get; }

    public {ServiceName}ValidationException(IEnumerable<string> errors) 
        : base("Validation failed.", "VALIDATION_ERROR")
    {
        Errors = errors.ToList().AsReadOnly();
    }
}
```

## Mappers/{ServiceName}Mapper.cs

```csharp
namespace {ServiceNamespace}.Mappers;

using System.Collections.Generic;
using System.Linq;
using {ResponseContractNamespace};
using {ServiceNamespace}.Models;

public static class {ServiceName}Mapper
{
    public static {ServiceName}Response ToResponse(this {ServiceName}Item item)
    {
        return new {ServiceName}Response(
            item.Id,
            item.Name,
            item.CreatedAt);
    }

    public static IEnumerable<{ServiceName}Response> ToResponses(this IEnumerable<{ServiceName}Item> items)
    {
        return items.Select(ToResponse);
    }
}
```

## {ServiceName}Service.cs

The base service imports only namespaces required by its unconditional implementation. Merge each optional
import only when the concrete selected capability makes the service file reference a type from that namespace:

| Selected service-file use | Import to merge |
|---------------------------|-----------------|
| Public response DTO appears in an implemented operation | `using {ResponseContractNamespace};` |
| Generated custom exception is thrown or caught | `using {ServiceNamespace}.Exceptions;` |
| Generated mapper is invoked | `using {ServiceNamespace}.Mappers;` |
| Internal model is referenced directly | `using {ServiceNamespace}.Models;` |

```csharp
namespace {ServiceNamespace};

using System;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Primitives;
using {ServiceNamespace}.Configuration;
using {ServiceContractNamespace};

public class {ServiceName}Service : I{ServiceName}
{
    private static readonly EventId OperationStarting = new(1000, nameof(OperationStarting));
    private static readonly EventId OperationCompleted = new(1001, nameof(OperationCompleted));
    private static readonly EventId OperationFailed = new(1002, nameof(OperationFailed));

    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly {ServiceName}Settings _settings;

    private readonly UpDownCounter<int> _activeRequests;
    private readonly Counter<long> _operationCounter;
    private readonly Histogram<double> _operationDuration;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options)
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

        _activeRequests = _meter.CreateUpDownCounter<int>(
            Constants.Metrics.ActiveRequests, "requests", "Active requests");
        _operationCounter = _meter.CreateCounter<long>(
            Constants.Metrics.OperationTotal, "operations", "Total operations");
        _operationDuration = _meter.CreateHistogram<double>(
            Constants.Metrics.OperationDuration, "s", "Operation duration");
    }

    public async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        using var activity = _tracer.StartActivity("DoWork", ActivityKind.Internal);
        activity.SetTag("app.service.name", nameof({ServiceName}));
        activity.SetTag("app.service.enabled", _settings.Enabled);

        using (_logger.BeginScope("{TraceId}, {SpanId}", activity.TraceId, activity.SpanId))
        {
            _activeRequests.Add(1);
            _operationCounter.Add(1);

            try
            {
                _logger.LogInformation(OperationStarting, "Starting operation");

                // Implementation
                await Task.Delay(1, cancellationToken);

                activity.SetStatus(ActivityStatusCode.Ok);
                _logger.LogInformation(OperationCompleted, "Operation completed");
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                activity.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity.SetTag("exception.type", ex.GetType().FullName);
                activity.SetTag("exception.message", ex.Message);
                activity.SetTag("exception.stacktrace", ex.StackTrace);
                _logger.LogError(OperationFailed, ex, "Operation failed");
                throw;
            }
            finally
            {
                _activeRequests.Add(-1);
                stopwatch.Stop();
                _operationDuration.Record(stopwatch.Elapsed.TotalSeconds);
            }
        }
    }
}
```

## {ServiceName}Worker.cs

See `background-service.md` for the Worker pattern and the `WorkerBackgroundService` base class. Worker owns lifecycle/scheduling. Service owns business logic. Worker calls Service, never the reverse.

## {EventName}Subscriber.cs

See `dependencies.md#imessagequeuefactory` for the long-lived broker subscriber pattern and its required event, settings, interface, and registration additions. The subscriber owns subscription lifecycle and resolves `I{ServiceName}` from a new scope per delivery; it does not contain business logic or use the scheduled-worker base class.

## {ServiceName}HealthCheck.cs

See `health-check.md` for the health check pattern and registration.

## Clients/

See `dependencies.md` for the typed HTTP client pattern (interface, implementation, and registration). Registration stays in `Extensions/StartupExtensions.cs` using `AddHttpClient<>`.

## Internals/{HelperName}.cs

`{HelperName}` is the descriptive PascalCase helper class name; its file and class names match. Internal helper
implementations include Repository, UnitOfWork, Decorator, Observer, and similar patterns. Their interfaces go
in `Contracts/`. The example below resolves `{HelperName}` to `DataSanitizer`.

```csharp
namespace {ServiceNamespace}.Internals;

internal class DataSanitizer : IDataSanitizer
{
    public string Sanitize(string input) => input.Trim().ToLowerInvariant();
}
```

## Observability/Grafana/dashboard.json

Per-service Grafana dashboard JSON. See observability skill for dashboard template standards.

## Resources/SQL/

Embedded SQL resource files, loaded lazily at runtime. Avoids inline SQL in C# code.
Resolve `{SqlScriptName}` from the descriptive PascalCase operation name defined by the canonical resource
entry in `solution-structure`; the coherent example below resolves it to `SelectForUpdate`.

SQL files must be set as **Embedded Resource** in the `.csproj`:

```xml
<ItemGroup>
  <EmbeddedResource Include="Resources\SQL\*.sql" />
</ItemGroup>
```

### Resources/SQL/Constants.cs

```csharp
namespace {ServiceNamespace}.Resources.SQL;

public static class Constants
{
    public const string SelectForUpdate = "SelectForUpdate.sql";
}
```

### Resources/SQL/ResourceLoader.cs

```csharp
namespace {ServiceNamespace}.Resources.SQL;

using System;
using System.IO;
using System.Text;
using System.Threading;

public static class ResourceLoader
{
    private static readonly Lazy<string> _selectForUpdate = new(
        () => Load(Constants.SelectForUpdate),
        LazyThreadSafetyMode.ExecutionAndPublication);
    
    public static string SelectForUpdate => _selectForUpdate.Value;

    private static string Load(string fileName)
    {
        var resourceName = $"{typeof(ResourceLoader).Namespace}.{fileName}";
        using var stream = typeof(ResourceLoader).Assembly.GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException($"Embedded resource '{resourceName}' was not found.");
        using var reader = new StreamReader(
            stream,
            Encoding.UTF8,
            detectEncodingFromByteOrderMarks: true);
        return reader.ReadToEnd();
    }
}
```

Usage in `{ServiceName}Service.cs`:

```csharp
using {ServiceNamespace}.Resources.SQL;

var sql = ResourceLoader.SelectForUpdate;
```

For other resource types (email templates, XML schemas, etc.), add subfolders under `Resources/`:

```
Resources/
├── SQL/
├── Templates/
└── Schemas/
```

## Extensions/StartupExtensions.cs

Resolve public method names through the generator's [Naming](../SKILL.md#naming) authority and adapter-specific
mapping through [`API Patterns`](api-patterns.md).

```csharp
namespace {ServiceNamespace}.Extensions;

using System;
using System.Diagnostics.Metrics;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Extensions.Configuration;
using Ruya.Extensions.DependencyInjection;
using Ruya.Primitives;
// Include this using only when versioned Minimal API exposure is selected.
using {ServiceNamespace}.Api;
using {ServiceNamespace}.Configuration;
using {ServiceContractNamespace};

public static class StartupExtensions
{
    public static IServiceCollection Add{ServiceName}Service(
        this IServiceCollection services,
        Action<{ServiceName}Settings>? setupAction = null)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.EnsureServicesRegistered(
            typeof(IDistributedTracing),
            typeof(IMeterFactory));

        services.AddOptions<{ServiceName}Settings>()
            .BindConfiguration({ServiceName}Settings.ConfigurationSectionName)
            .Configure<IConfiguration>((settings, config) =>
            {
                settings.Enabled = config.GetFeatureFlag<{ServiceName}Settings>();
            })
            .ValidateDataAnnotations()
            // Include only when ApiBaseUrl is selected.
            .Validate(
                settings => !settings.Enabled || !string.IsNullOrWhiteSpace(settings.ApiBaseUrl),
                "ApiBaseUrl is required when the service is enabled.")
            .ValidateOnStart();

        // Example: include when a RabbitMQ management connection is selected.
        services.AddOptions<RabbitMqSettings>()
            .BindConfiguration(RabbitMqSettings.ConfigurationSectionName)
            .Validate<IConfiguration, IOptions<{ServiceName}Settings>>(
                (settings, configuration, serviceOptions) => !serviceOptions.Value.Enabled ||
                    HasValidRabbitMqManagementConnectionString(settings, configuration),
                "ManagementConnectionStringKey must identify a configured absolute HTTP or HTTPS connection string when the service is enabled.")
            .ValidateOnStart();

        if (setupAction is not null)
        {
            services.Configure(setupAction);
        }

        services.Add{ServiceLifetime}<I{ServiceName}, {ServiceName}Service>();

        return services;
    }

    // Example: keep the resolved value local and never include it in validation messages or logs.
    private static bool HasValidRabbitMqManagementConnectionString(
        RabbitMqSettings settings,
        IConfiguration configuration)
    {
        if (string.IsNullOrWhiteSpace(settings.ManagementConnectionStringKey))
        {
            return false;
        }

        var connectionString = configuration.GetConnectionString(
            settings.ManagementConnectionStringKey);

        return Uri.TryCreate(connectionString, UriKind.Absolute, out var uri) &&
            uri.Scheme is Uri.UriSchemeHttp or Uri.UriSchemeHttps;
    }

    // Include this method only when versioned Minimal API exposure is selected.
    public static WebApplication Map{ServiceName}Service(
        this WebApplication app,
        bool enabled)
    {
        ArgumentNullException.ThrowIfNull(app);

        if (!enabled)
        {
            return app;
        }

        var serviceProviderIsService =
            app.Services.GetRequiredService<IServiceProviderIsService>();

        if (!serviceProviderIsService.IsService(typeof(I{ServiceName})))
        {
            throw new InvalidOperationException(
                "Cannot map {ServiceName} endpoints because I{ServiceName} is not registered. " +
                "Run the parent registration cascade before endpoint mapping.");
        }

        app.Map{ServiceName}Api();
        return app;
    }
}
```
