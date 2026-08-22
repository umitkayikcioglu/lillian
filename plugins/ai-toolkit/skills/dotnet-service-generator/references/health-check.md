# Health Check Pattern

Custom health checks for services using `IHealthCheck`.

## Required addition to the resolved I{ServiceName} contract

When service-specific health monitoring is selected, merge this capability into the existing service
contract and implement it in `{ServiceName}Service`. Its default file is
`Contracts/I{ServiceName}.cs`; if the interface was placed at a broader consumer boundary, update that
resolved owning file instead. Do not generate a second interface or move only this operation back into the
service implementation project.

```csharp
Task<bool> IsHealthyAsync(CancellationToken cancellationToken);
```

The implementation must perform a lightweight, side-effect-free readiness check and pass `cancellationToken` to every asynchronous dependency call.

## {ServiceName}HealthCheck.cs

```csharp
namespace {ServiceNamespace};

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using {ServiceNamespace}.Configuration;
using {ServiceContractNamespace};

public class {ServiceName}HealthCheck : IHealthCheck
{
    private readonly I{ServiceName} _service;
    private readonly {ServiceName}Settings _settings;

    public {ServiceName}HealthCheck(
        I{ServiceName} service,
        IOptions<{ServiceName}Settings> options)
    {
        _service = service;
        _settings = options.Value;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled)
        {
            return HealthCheckResult.Healthy("Service disabled.");
        }

        try
        {
            // Service-specific health validation
            var isHealthy = await _service.IsHealthyAsync(cancellationToken);
            
            return isHealthy
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy("Service health check failed.");
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Health check exception.", ex);
        }
    }
}
```

## Registration in Extensions/StartupExtensions.cs

```csharp
services.AddHealthChecks()
    .AddCheck<{ServiceName}HealthCheck>("{ServiceName}", tags: ["ready"]);
```

## Complete dependency health-check files

When a worker requires a custom startup check, generate exactly one complete file from the applicable pattern
below. `{DependencyName}` is the confirmed PascalCase dependency identity used by the worker registration.
Do not paste a method fragment into an otherwise undefined class. Caller-requested cancellation is control
flow, not an unhealthy result, so every pattern propagates it before handling dependency failures.

These patterns intentionally cover only HTTP, `IDistributedCache`, and Entity Framework connectivity. For a
different dependency—such as distributed locking, cloud storage, or a message broker—use a concrete health
check already supplied by the selected integration. Otherwise require the user to confirm a side-effect-free
readiness operation, its contract type, and its success/failure semantics before creating a complete custom
file. If that contract is unavailable, stop and report the missing startup-gate capability. Never extrapolate
one of the patterns below into an unrelated integration or register a check that cannot be implemented.

### {DependencyName}HealthCheck.cs — HTTP dependency

The named `HttpClient` registration for `{DependencyName}` must already own its base address, authentication,
timeout, and resilience policy.

```csharp
namespace {ServiceNamespace};

using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

public sealed class {DependencyName}HealthCheck : IHealthCheck
{
    private readonly IHttpClientFactory _httpClientFactory;

    public {DependencyName}HealthCheck(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory
            ?? throw new ArgumentNullException(nameof(httpClientFactory));
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        using var timeoutSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutSource.CancelAfter(TimeSpan.FromSeconds(5));

        try
        {
            var httpClient = _httpClientFactory.CreateClient("{DependencyName}");
            using var response = await httpClient.GetAsync(
                "/health",
                HttpCompletionOption.ResponseHeadersRead,
                timeoutSource.Token);

            return response.IsSuccessStatusCode
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy(
                    $"Dependency returned HTTP {(int)response.StatusCode}.");
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException ex)
        {
            return HealthCheckResult.Unhealthy("Dependency health check timed out.", ex);
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Dependency unavailable.", ex);
        }
    }
}
```

### {DependencyName}HealthCheck.cs — distributed cache

Use this only when a harmless write/remove probe is valid for the selected cache implementation.

```csharp
namespace {ServiceNamespace};

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Diagnostics.HealthChecks;

public sealed class {DependencyName}HealthCheck : IHealthCheck
{
    private readonly IDistributedCache _distributedCache;

    public {DependencyName}HealthCheck(IDistributedCache distributedCache)
    {
        _distributedCache = distributedCache
            ?? throw new ArgumentNullException(nameof(distributedCache));
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var testKey = $"health:{Guid.NewGuid()}";
            await _distributedCache.SetStringAsync(testKey, "ok", cancellationToken);
            await _distributedCache.RemoveAsync(testKey, cancellationToken);
            return HealthCheckResult.Healthy();
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Cache unavailable.", ex);
        }
    }
}
```

### {DependencyName}HealthCheck.cs — Entity Framework database

Confirm `{DbContextName}` from the selected persistence dependency and substitute the concrete context type.

```csharp
namespace {ServiceNamespace};

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;

public sealed class {DependencyName}HealthCheck : IHealthCheck
{
    private readonly {DbContextName} _dbContext;

    public {DependencyName}HealthCheck({DbContextName} dbContext)
    {
        _dbContext = dbContext
            ?? throw new ArgumentNullException(nameof(dbContext));
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var canConnect = await _dbContext.Database.CanConnectAsync(cancellationToken);
            return canConnect
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy("Database unavailable.");
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database unavailable.", ex);
        }
    }
}
```

## Tags

| Tag | Purpose |
|-----|---------|
| `ready` | Readiness probe - can accept traffic |
| `live` | Liveness probe - process is running |
| `startup` | Startup probe - initialization complete |
