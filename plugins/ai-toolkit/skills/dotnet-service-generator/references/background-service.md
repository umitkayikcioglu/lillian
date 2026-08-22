# Background Service Pattern

Extends `WorkerBackgroundService<TSettings>` for discrete scheduled or polling executions. A long-lived broker subscription is event-driven rather than continuous polling; use the [`IMessageQueueFactory` subscriber pattern](dependencies.md#imessagequeuefactory) instead.

## File Structure

Use the canonical service layout from [`solution-structure`](../../solution-structure/SKILL.md#net-solution-folder-structure). This pattern fills the optional scheduled-worker files:

- `Configuration/{ServiceName}Settings.cs` extends `WorkerBackgroundServiceSettings`.
- `{ServiceName}Worker.cs` extends `WorkerBackgroundService<{ServiceName}Settings>`.
- `{ServiceName}HealthCheck.cs` is added only when the worker needs service-specific health monitoring.

Do not add an `{EventName}Subscriber.cs` for scheduled or polling work; that file is reserved for a long-lived broker subscription.

## Features

| Feature | Behavior |
|---------|----------|
| Schedule | Six-field Cronos expression (including seconds), continuous polling, or one-shot |
| Idle Backoff | Configurable delay when `IdleCycle = true` (no data), `TimeSpan.Zero` = disabled |
| Delay Between Executions | Fixed delay between consecutive executions, `TimeSpan.Zero` = disabled |
| Health | `IHealthCheck` - unhealthy if degraded or no completion in X time |
| Retry | Optional for explicitly transient failures only; bounded exponential backoff + jitter, configurable count (default 3) |
| Fatal/exhausted failure | Records failure, requests application stop, and rethrows; never leaves a silently faulted loop |
| Execution ordering | Runs sequentially within each worker instance; the next delay or schedule is evaluated after the current execution completes |
| Startup | Fail fast - executes only `HealthCheckService` registrations tagged `startup` before first execution |
| Shutdown | Graceful within a configurable application timeout |
| Observability | Base provides protected meter/tracer, derived adds service-specific metrics |

> **Warning -- Continuous mode**: When `ScheduleCronExpression` is null/empty, a zero
> `DelayBetweenExecutions` permits immediate non-idle iterations. Set a non-zero value (for example,
> `"00:00:01"`) unless a measured use case explicitly requires a tight loop. Idle cycles use
> `IdleBackoffDuration` when configured.

## Required Extensions

[Ruya.Extensions.Hosting](https://github.com/cilerler/ruya/blob/main/src/Ruya.Extensions.Hosting/README.md) is the reference implementation of the shared contracts below. A compatible organization-owned library may provide the same contracts under its own namespace.

### ScheduleValidationAttribute.cs

```csharp
using System;
using System.ComponentModel.DataAnnotations;
using Cronos;

namespace Ruya.Extensions.Hosting.Validators;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field, AllowMultiple = false)]
public sealed class ScheduleValidationAttribute : ValidationAttribute
{
    public bool AllowEmpty { get; set; } = false;

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var expression = value?.ToString();

        if (string.IsNullOrWhiteSpace(expression))
        {
            return AllowEmpty
                ? ValidationResult.Success
                : new ValidationResult("Schedule expression is required unless continuous mode is intended.");
        }

        try
        {
            CronExpression.Parse(expression, CronFormat.IncludeSeconds);
            return ValidationResult.Success;
        }
        catch (CronFormatException)
        {
            return new ValidationResult(ErrorMessage ?? "Invalid cron expression.");
        }
    }
}
```

## WorkerBackgroundServiceSettings

```csharp
using System;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using System.Threading;
using Cronos;
using Ruya.Extensions.Hosting.Validators;

namespace Ruya.Extensions.Hosting;

public class WorkerBackgroundServiceSettings
{
    public const string ConfigurationSectionName = nameof(WorkerBackgroundService<WorkerBackgroundServiceSettings>);
    public static readonly string FeatureFlag = ConfigurationSectionName;

    [JsonIgnore]
    public bool Enabled { get; set; }
    public bool RunOnce { get; set; }
    public bool RunImmediately { get; set; }

    [ScheduleValidation(AllowEmpty = true, ErrorMessage = "Invalid schedule expression.")]
    public string? ScheduleCronExpression { get; set; }

    // Retry settings
    public bool RetryEnabled { get; set; } = false;

    [Range(0, 100)]
    public int RetryCount { get; set; } = 3;

    [Range(1, 3600)]
    public int RetryBaseDelaySeconds { get; set; } = 1;

    [Range(1, 3600)]
    public int RetryMaxDelaySeconds { get; set; } = 30;

    // Health settings
    [Range(1, 1000)]
    public int HealthSampleSize { get; set; } = 5;

    [Range(1.0, 100.0)]
    public double HealthDegradedThresholdMultiplier { get; set; } = 2.0;
    public TimeSpan? HealthHardTimeout { get; set; }

    // Shutdown settings
    public TimeSpan ShutdownTimeout { get; set; } = TimeSpan.FromSeconds(30);

    // Delay settings
    public TimeSpan DelayBetweenExecutions { get; set; } = TimeSpan.Zero;

    // Idle backoff settings
    public TimeSpan IdleBackoffDuration { get; set; } = TimeSpan.Zero;

    public bool RunContinuously => string.IsNullOrWhiteSpace(ScheduleCronExpression);

    public TimeSpan NextOccurrence
    {
        get
        {
            if (!Enabled || RunOnce) return Timeout.InfiniteTimeSpan;
            if (RunContinuously) return TimeSpan.Zero;

            var expression = CronExpression.Parse(ScheduleCronExpression!, CronFormat.IncludeSeconds);
            var next = expression.GetNextOccurrence(DateTimeOffset.UtcNow, TimeZoneInfo.Local);
			if (next == null) throw new InvalidOperationException("Failed to calculate the next occurrence from the cron expression.");
            return next == DateTimeOffset.MinValue ? Timeout.InfiniteTimeSpan : (DateTimeOffset)next - DateTimeOffset.UtcNow;
        }
    }
}
```

## WorkerBackgroundService Base Class

```csharp
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Primitives;

namespace Ruya.Extensions.Hosting;

public abstract class WorkerBackgroundService<TSettings> : IHostedLifecycleService, IDisposable
    where TSettings : WorkerBackgroundServiceSettings
{
    private static readonly EventId StartupValidationSkipped = new(1000, nameof(StartupValidationSkipped));
    private static readonly EventId StartupValidationStarting = new(1001, nameof(StartupValidationStarting));
    private static readonly EventId StartupValidationCompleted = new(1002, nameof(StartupValidationCompleted));
    private static readonly EventId ServiceDisabled = new(1003, nameof(ServiceDisabled));
    private static readonly EventId ShutdownStarting = new(1004, nameof(ShutdownStarting));
    private static readonly EventId ShutdownCompleted = new(1005, nameof(ShutdownCompleted));
    private static readonly EventId ShutdownHostCancelled = new(1006, nameof(ShutdownHostCancelled));
    private static readonly EventId ShutdownTimedOut = new(1007, nameof(ShutdownTimedOut));
    private static readonly EventId ShutdownCancelled = new(1008, nameof(ShutdownCancelled));
    private static readonly EventId ShutdownFailed = new(1009, nameof(ShutdownFailed));
    private static readonly EventId ServiceStopped = new(1010, nameof(ServiceStopped));
    private static readonly EventId ExecutionModeSelected = new(1011, nameof(ExecutionModeSelected));
    private static readonly EventId InitialExecutionSkipped = new(1012, nameof(InitialExecutionSkipped));
    private static readonly EventId RunOnceCompleted = new(1013, nameof(RunOnceCompleted));
    private static readonly EventId LoopDelayStarting = new(1014, nameof(LoopDelayStarting));
    private static readonly EventId ScheduleCompleted = new(1015, nameof(ScheduleCompleted));
    private static readonly EventId ScheduleDelayStarting = new(1016, nameof(ScheduleDelayStarting));
    private static readonly EventId ExecutionStarting = new(1017, nameof(ExecutionStarting));
    private static readonly EventId ExecutionCompleted = new(1018, nameof(ExecutionCompleted));
    private static readonly EventId ExecutionCancelled = new(1019, nameof(ExecutionCancelled));
    private static readonly EventId ExecutionFailed = new(1020, nameof(ExecutionFailed));
    private static readonly EventId ExecutionRetrying = new(1021, nameof(ExecutionRetrying));

#pragma warning disable IDE1006
    protected readonly ILogger _logger;
    protected readonly IDistributedTracing _tracer;
    protected readonly Meter _meter;
    protected readonly TSettings _settings;
#pragma warning restore IDE1006

    private readonly HealthCheckService _healthCheckService;
    private readonly IHostApplicationLifetime _hostApplicationLifetime;
    private readonly CancellationTokenSource _cancellationTokenSource = new();
    private readonly object _statisticsLock = new ();

    // Health tracking (thread-safe via _statisticsLock)
    private readonly Queue<double> _executionDurations = new();
    private double _lastExecutionDuration;
    private DateTimeOffset _lastSuccessfulCompletion = DateTimeOffset.UtcNow;

    // Metrics
    private readonly UpDownCounter<int> _activeExecutions;
    private readonly Counter<long> _executionTotal;
    private readonly Counter<long> _executionSuccess;
    private readonly Counter<long> _executionFailed;
    private readonly Counter<long> _retryTotal;
    private readonly Histogram<double> _executionDuration;

    private Task? _executingTask;

    protected WorkerBackgroundService(
        ILogger<WorkerBackgroundService<TSettings>> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<TSettings> options,
        HealthCheckService healthCheckService,
        IHostApplicationLifetime hostApplicationLifetime)
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
        _healthCheckService = healthCheckService;
        _hostApplicationLifetime = hostApplicationLifetime;

        var serviceName = JsonNamingPolicy.SnakeCaseLower.ConvertName(GetType().Name);
        _activeExecutions = _meter.CreateUpDownCounter<int>(
            $"app_{serviceName}_active", "executions", "Currently active executions across instances");
        _executionTotal = _meter.CreateCounter<long>(
            $"app_{serviceName}_total", "executions", "Total execution attempts");
        _executionSuccess = _meter.CreateCounter<long>(
            $"app_{serviceName}_success", "executions", "Successful executions");
        _executionFailed = _meter.CreateCounter<long>(
            $"app_{serviceName}_failed", "executions", "Failed executions");
        _retryTotal = _meter.CreateCounter<long>(
            $"app_{serviceName}_retries", "retries", "Total retry attempts");
        _executionDuration = _meter.CreateHistogram<double>(
            $"app_{serviceName}_duration_seconds", "s", "Execution duration");
    }

    protected bool IdleCycle { get; set; }

    public abstract Task DoWorkAsync(CancellationToken cancellationToken);

    protected abstract bool IsTransient(Exception exception);

    #region IHostedLifecycleService

    public async Task StartingAsync(CancellationToken cancellationToken)
    {
        if (!_settings.Enabled)
        {
            _logger.LogDebug(
                StartupValidationSkipped,
                "Service {ServiceName} is disabled. Skipping startup validation.",
                GetType().Name);
            return;
        }

        _logger.LogDebug(StartupValidationStarting, "Service starting. Validating dependencies.");

        var result = await _healthCheckService.CheckHealthAsync(
            registration => registration.Tags.Contains("startup", StringComparer.Ordinal),
            cancellationToken);

        if (result.Status != HealthStatus.Healthy)
        {
            var failedChecks = string.Join(
                ", ",
                result.Entries
                    .Where(entry => entry.Value.Status != HealthStatus.Healthy)
                    .Select(entry => $"{entry.Key}={entry.Value.Status}"));
            throw new InvalidOperationException(
                $"Startup dependency health checks failed: {failedChecks}.");
        }

        _logger.LogDebug(StartupValidationCompleted, "All startup dependency health checks passed.");
    }

    public Task StartedAsync(CancellationToken cancellationToken)
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation(ServiceDisabled, "Service {ServiceName} is disabled.", GetType().Name);
            return Task.CompletedTask;
        }

        _executingTask = RunScheduleLoopAsync(_cancellationTokenSource.Token);
        return Task.CompletedTask;
    }

    public async Task StoppingAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation(ShutdownStarting, "Host shutdown requested. Initiating graceful shutdown.");
        await _cancellationTokenSource.CancelAsync();

        var executingTask = _executingTask;
        if (executingTask is null)
        {
            return;
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(_settings.ShutdownTimeout);

        try
        {
            await executingTask.WaitAsync(timeoutCts.Token);
            _logger.LogInformation(ShutdownCompleted, "Work completed gracefully.");
        }
        catch (OperationCanceledException) when (!executingTask.IsCompleted && cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(
                ShutdownHostCancelled,
                "Host shutdown cancellation was requested before work completed.");
        }
        catch (OperationCanceledException) when (!executingTask.IsCompleted && timeoutCts.IsCancellationRequested)
        {
            _logger.LogWarning(
                ShutdownTimedOut,
                "Shutdown timeout ({ShutdownTimeout}) exceeded. Work may be incomplete.",
                _settings.ShutdownTimeout);
        }
        catch (OperationCanceledException) when (executingTask.IsCanceled)
        {
            _logger.LogInformation(ShutdownCancelled, "Shutdown completed via cancellation.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ShutdownFailed, ex, "Error during shutdown.");
            throw;
        }
    }

    public Task StoppedAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation(ServiceStopped, "Service stopped.");
        return Task.CompletedTask;
    }

    public Task StartAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    #endregion

    #region Execution

    private async Task RunScheduleLoopAsync(CancellationToken cancellationToken)
    {
        // Yield to ensure the loop runs asynchronously and doesn't block StartedAsync
        await Task.Yield();
        
        var mode = _settings.RunContinuously ? "continuous" : $"schedule: {_settings.ScheduleCronExpression}";
        _logger.LogInformation(ExecutionModeSelected, "Service running in {Mode} mode.", mode);

        var isFirstExecution = true;
        while (!cancellationToken.IsCancellationRequested)
        {
            var shouldExecute = _settings.RunOnce || !isFirstExecution || _settings.RunImmediately || _settings.RunContinuously;
            if (shouldExecute)
            {
                IdleCycle = false;
                await ExecuteWorkAsync(cancellationToken);
            }
            else
            {
                _logger.LogInformation(
                    InitialExecutionSkipped,
                    "Skipping initial execution (RunImmediately=false).");
            }

            isFirstExecution = false;

            if (cancellationToken.IsCancellationRequested) break;

            if (_settings.RunOnce)
            {
                _logger.LogInformation(
                    RunOnceCompleted,
                    "Run-once execution completed. No further executions scheduled.");
                break;
            }

            if (_settings.RunContinuously)
            {
                var loopDelay = IdleCycle && _settings.IdleBackoffDuration > TimeSpan.Zero
                    ? _settings.IdleBackoffDuration
                    : _settings.DelayBetweenExecutions;

                if (loopDelay > TimeSpan.Zero)
                {
                    _logger.LogDebug(
                        LoopDelayStarting,
                        IdleCycle
                            ? "Idle cycle detected. Backing off for {Duration}."
                            : "Waiting {Duration} before next execution.",
                        loopDelay);
                    try
                    {
                        await Task.Delay(loopDelay, cancellationToken);
                    }
                    catch (TaskCanceledException)
                    {
                        break;
                    }
                }

                continue;
            }

            if (cancellationToken.IsCancellationRequested) break;

            // Cron owns the scheduled delay. DelayBetweenExecutions applies only to continuous polling.
            var delay = _settings.NextOccurrence;
            if (delay == Timeout.InfiniteTimeSpan)
            {
                _logger.LogInformation(ScheduleCompleted, "No further executions scheduled.");
                break;
            }

            if (delay > TimeSpan.Zero)
            {
                _logger.LogInformation(ScheduleDelayStarting, "Next execution in {Delay}.", delay);
                try
                {
                    await Task.Delay(delay, cancellationToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }
        }
    }

    private async Task ExecuteWorkAsync(CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        _activeExecutions.Add(1);
        _executionTotal.Add(1);

        try
        {
            using (_logger.BeginScope("{ExecutionId}", Guid.NewGuid()))
            {
                _logger.LogDebug(ExecutionStarting, "Starting execution.");

                await ExecuteWithRetryAsync(cancellationToken);

                stopwatch.Stop();
                RecordSuccess(stopwatch.Elapsed.TotalSeconds);
                _logger.LogDebug(
                    ExecutionCompleted,
                    "Execution completed in {Duration:F2}s.",
                    stopwatch.Elapsed.TotalSeconds);
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            _logger.LogInformation(ExecutionCancelled, "Execution cancelled.");
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            RecordFailure(stopwatch.Elapsed.TotalSeconds);
            _logger.LogError(ExecutionFailed, ex, "Execution failed after retries.");
            _hostApplicationLifetime.StopApplication();
            throw;
        }
        finally
        {
            _activeExecutions.Add(-1);
        }
    }

    private async Task ExecuteWithRetryAsync(CancellationToken cancellationToken)
    {
        var maxAttempts = _settings.RetryEnabled ? _settings.RetryCount + 1 : 1;

        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                await DoWorkAsync(cancellationToken);
                return;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex) when (attempt < maxAttempts && IsTransient(ex))
            {
                _retryTotal.Add(1);
                var delay = CalculateBackoffWithJitter(attempt);
                _logger.LogWarning(
                    ExecutionRetrying,
                    ex,
                    "Attempt {Attempt}/{Max} failed. Retrying in {DelayMs}ms.",
                    attempt,
                    maxAttempts,
                    delay.TotalMilliseconds);
                await Task.Delay(delay, cancellationToken);
            }
        }
    }

    private TimeSpan CalculateBackoffWithJitter(int attempt)
    {
        const double JitterFactor = 0.5;
        var exponentialDelay = _settings.RetryBaseDelaySeconds * Math.Pow(2, attempt - 1);
        var cappedDelay = Math.Min(_settings.RetryMaxDelaySeconds, exponentialDelay);
        var jitterCapacity = _settings.RetryMaxDelaySeconds - cappedDelay;
        var jitter = Random.Shared.NextDouble() * Math.Min(jitterCapacity, JitterFactor * cappedDelay);
        return TimeSpan.FromSeconds(cappedDelay + jitter);
    }

    #endregion

    #region Health Tracking

    private void RecordSuccess(double elapsedSeconds)
    {
        _executionSuccess.Add(1);
        _executionDuration.Record(elapsedSeconds);

        lock (_statisticsLock)
        {
            _lastExecutionDuration = elapsedSeconds;
            _executionDurations.Enqueue(elapsedSeconds);
            while (_executionDurations.Count > _settings.HealthSampleSize)
            {
                _executionDurations.Dequeue();
            }
            _lastSuccessfulCompletion = DateTimeOffset.UtcNow;
        }
    }

    private void RecordFailure(double elapsedSeconds)
    {
        _executionFailed.Add(1);
        _executionDuration.Record(elapsedSeconds);

        lock (_statisticsLock)
        {
            _lastExecutionDuration = elapsedSeconds;
        }
    }

    public double? GetAverageExecutionDuration()
    {
        lock (_statisticsLock)
        {
            return _executionDurations.Count > 0 ? _executionDurations.Average() : null;
        }
    }

    public double GetLastExecutionDuration()
    {
        lock (_statisticsLock)
        {
            return _lastExecutionDuration;
        }
    }

    public DateTimeOffset GetLastSuccessfulCompletion()
    {
        lock (_statisticsLock)
        {
            return _lastSuccessfulCompletion;
        }
    }

    #endregion

    public void Dispose()
    {
        _cancellationTokenSource.Dispose();
		_meter.Dispose();
        GC.SuppressFinalize(this);
    }
}
```

## Configuration/{ServiceName}Settings.cs

```csharp
namespace {ServiceNamespace}.Configuration;

using Ruya.Extensions.Hosting;

public class {ServiceName}Settings : WorkerBackgroundServiceSettings
{
    public new const string ConfigurationSectionName = nameof({ServiceName});
    public new static readonly string FeatureFlag = ConfigurationSectionName;

    // Add service-specific settings here
}
```

## {ServiceName}HealthCheck.cs

```csharp
namespace {ServiceNamespace};

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using {ServiceNamespace}.Configuration;

public class {ServiceName}HealthCheck : IHealthCheck
{
    private readonly {ServiceName}Worker _worker;
    private readonly {ServiceName}Settings _settings;

    public {ServiceName}HealthCheck({ServiceName}Worker worker, IOptions<{ServiceName}Settings> options)
    {
        _worker = worker;
        _settings = options.Value;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled)
        {
            return Task.FromResult(HealthCheckResult.Healthy("Service is disabled."));
        }

        // Hard timeout check - no successful completion in X time
        if (_settings.HealthHardTimeout.HasValue)
        {
            var timeSinceLastSuccess = DateTimeOffset.UtcNow - _worker.GetLastSuccessfulCompletion();
            if (timeSinceLastSuccess > _settings.HealthHardTimeout.Value)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy(
                    $"No successful completion in {timeSinceLastSuccess:g}."));
            }
        }

        // Degraded check - last execution took significantly longer than average
        var average = _worker.GetAverageExecutionDuration();
        if (average.HasValue)
        {
            var lastDuration = _worker.GetLastExecutionDuration();
            var threshold = average.Value * _settings.HealthDegradedThresholdMultiplier;

            if (lastDuration > threshold)
            {
                return Task.FromResult(HealthCheckResult.Degraded(
                    $"Last execution ({lastDuration:F2}s) exceeded threshold ({threshold:F2}s). Average: {average:F2}s"));
            }
        }

        return Task.FromResult(HealthCheckResult.Healthy());
    }
}
```

## {ServiceName}Worker.cs and {ServiceName}Service.cs

> **Separation of concerns**: Worker handles scheduling, retries, sequential execution, and health. Service handles business logic. This makes business logic testable without standing up a hosted service, and lets you swap the trigger (cron, queue, HTTP) without touching business logic.

When the scheduled/polling capability is selected, replace the neutral `I{ServiceName}.DoWorkAsync` placeholder with these operations:

```csharp
Task<bool> ProcessAsync(CancellationToken cancellationToken);
```

Return `true` when an execution performed work and `false` when a polling cycle found nothing; the worker uses that result to apply idle backoff without a separate check-then-process race.

Add the business metric used by the example to `Constants.Metrics`:

```csharp
public const string ItemsProcessed = "app_{ServiceSnakeName}_items_processed";
```

### {ServiceName}Service.cs

```csharp
namespace {ServiceNamespace};

using System;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.Metrics;
using Microsoft.Extensions.Logging;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Primitives;
using {ServiceContractNamespace};

public class {ServiceName}Service : I{ServiceName}
{
    private static readonly EventId BatchCompleted = new(2000, nameof(BatchCompleted));
    private static readonly EventId BatchFailed = new(2001, nameof(BatchFailed));

    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly Counter<long> _itemsProcessed;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory)
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

        _itemsProcessed = _meter.CreateCounter<long>(
            Constants.Metrics.ItemsProcessed, "items", "Items processed");
    }

    public async Task<bool> ProcessAsync(CancellationToken cancellationToken)
    {
        using var activity = _tracer.StartActivity("ProcessBatch", ActivityKind.Internal);
        activity.SetTag("app.service.name", nameof({ServiceName}));

        try
        {
            // Replace with the real business operation.
            await Task.Delay(1, cancellationToken);

            const int processed = 1;
            _itemsProcessed.Add(processed);
            activity.SetStatus(ActivityStatusCode.Ok);
            _logger.LogInformation(BatchCompleted, "Batch completed. Processed {Count} items.", processed);
            return processed > 0;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            activity.SetStatus(ActivityStatusCode.Error, ex.Message);
            _logger.LogError(BatchFailed, ex, "Batch failed");
            throw;
        }
    }
}
```

### {ServiceName}Worker.cs

```csharp
namespace {ServiceNamespace};

using System;
using System.Diagnostics.Metrics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Extensions.Hosting;
using Ruya.Primitives;
using {ServiceNamespace}.Configuration;
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public class {ServiceName}Worker : WorkerBackgroundService<{ServiceName}Settings>
{
    private readonly I{ServiceName} _service;

    public {ServiceName}Worker(
        ILogger<{ServiceName}Worker> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IOptions<{ServiceName}Settings> options,
        HealthCheckService healthCheckService,
        IHostApplicationLifetime hostApplicationLifetime,
        I{ServiceName} service)
        : base(
            logger,
            distributedTracing,
            meterFactory,
            options,
            healthCheckService,
            hostApplicationLifetime)
    {
        _service = service;
    }

    public override async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        IdleCycle = !await _service.ProcessAsync(cancellationToken);
    }

    protected override bool IsTransient(Exception exception) =>
        exception is {ServiceName}TransientException or TimeoutException or TaskCanceledException;
}
```

## Extensions/StartupExtensions.cs

```csharp
namespace {ServiceNamespace}.Extensions;

using System;
using System.Diagnostics.Metrics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Extensions.Configuration;
using Ruya.Extensions.DependencyInjection;
using Ruya.Primitives;
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
            .Validate(
                settings => settings.RetryMaxDelaySeconds >= settings.RetryBaseDelaySeconds,
                "RetryMaxDelaySeconds must be greater than or equal to RetryBaseDelaySeconds.")
            .Validate(
                settings => settings.HealthHardTimeout is null || settings.HealthHardTimeout > TimeSpan.Zero,
                "HealthHardTimeout must be positive when configured.")
            .Validate(
                settings => settings.ShutdownTimeout > TimeSpan.Zero,
                "ShutdownTimeout must be positive.")
            .Validate(
                settings => settings.DelayBetweenExecutions >= TimeSpan.Zero,
                "DelayBetweenExecutions cannot be negative.")
            .Validate(
                settings => settings.IdleBackoffDuration >= TimeSpan.Zero,
                "IdleBackoffDuration cannot be negative.")
            .ValidateOnStart();

        if (setupAction is not null)
        {
            services.Configure(setupAction);
        }

        services.AddSingleton<I{ServiceName}, {ServiceName}Service>();
        services.AddSingleton<{ServiceName}Worker>();
        services.AddHostedService(sp => sp.GetRequiredService<{ServiceName}Worker>());
        services.AddHealthChecks();

        return services;
    }

}
```

When service-specific health monitoring is selected, append the readiness registration separately:

```csharp
services.AddHealthChecks()
    .AddCheck<{ServiceName}HealthCheck>("{ServiceName}", tags: ["ready"]);
```

Register dependency checks that must pass before the worker starts with the `startup` tag. The base class
executes only that tag through `HealthCheckService`; it deliberately excludes the worker's own readiness
check, avoiding a `worker -> health check -> worker` construction cycle:

`{DependencyName}` is the exact PascalCase name of the required startup dependency selected for this worker.
The registration below is emitted only when that concrete `{DependencyName}HealthCheck` type already comes
from the selected integration or the generator creates `{DependencyName}HealthCheck.cs` from the applicable
dependency-specific pattern in [`health-check.md`](health-check.md). Never register an invented or missing
type. For a dependency not covered by a complete pattern, require an integration-owned check or a
user-confirmed side-effect-free readiness contract; otherwise stop before generating the worker startup gate.
Substitute the confirmed dependency name consistently in the file, type, and registration name.

```csharp
services.AddHealthChecks()
    .AddCheck<{DependencyName}HealthCheck>("{DependencyName}", tags: ["startup", "ready"]);
```

> **Registration notes**: The shown `AddSingleton<I{ServiceName}, {ServiceName}Service>()` and direct worker injection are the singleton-compatible branch. The worker must be exposed to the host via `AddHostedService` — the host only starts hosted services registered as `IHostedService` (the `IHostedLifecycleService` hooks are discovered through that same registration). The `AddSingleton<{ServiceName}Worker>()` + factory pair ensures the host and any other consumers share one worker instance. Apply the lifetime selected in Step 4 to `I{ServiceName}`. For a scoped service use `AddScoped`; for a transient service use `AddTransient`. In either of those branches, inject `IServiceScopeFactory` into the singleton worker and resolve `I{ServiceName}` from a new async scope inside each execution; never capture the service in the worker constructor:

```csharp
private readonly IServiceScopeFactory _scopeFactory;

// Replace the I{ServiceName} constructor parameter with:
IServiceScopeFactory scopeFactory

// Constructor body:
_scopeFactory = scopeFactory;

public override async Task DoWorkAsync(CancellationToken cancellationToken)
{
    await using var scope = _scopeFactory.CreateAsyncScope();
    var service = scope.ServiceProvider.GetRequiredService<I{ServiceName}>();
    IdleCycle = !await service.ProcessAsync(cancellationToken);
}
```

API mapping is independent of the worker. Apply the selected adapter's mapping contract from
[`API Patterns`](api-patterns.md); the worker does not add or alter an API mapper.

## Configuration

```json
{
  "FeatureManagement": {
    "{ServiceName}": true
  },
  "{ServiceName}": {
    "RunOnce": false,
    "RunImmediately": true,
    "ScheduleCronExpression": "0 */5 * * * *",
    "RetryEnabled": true,
    "RetryCount": 3,
    "RetryBaseDelaySeconds": 1,
    "RetryMaxDelaySeconds": 30,
    "DelayBetweenExecutions": "00:00:00",
    "IdleBackoffDuration": "00:00:30",
    "HealthSampleSize": 5,
    "HealthDegradedThresholdMultiplier": 2.0,
    "HealthHardTimeout": "01:00:00",
    "ShutdownTimeout": "00:00:30"
  }
}
```

| Setting | Description |
|---------|-------------|
| `ScheduleCronExpression` | Six-field Cronos expression including seconds; null/empty = continuous polling |
| `RunOnce` | Execute once immediately, then stop |
| `RunImmediately` | Execute once on startup before entering a scheduled loop; ignored when `RunOnce = true` |
| `RetryEnabled` | Enable exponential backoff + jitter |
| `RetryCount` | Retries after the initial attempt (default 3) |
| `RetryBaseDelaySeconds` | Base delay for backoff (default 1) |
| `RetryMaxDelaySeconds` | Maximum retry delay after exponential backoff and jitter (default 30) |
| `DelayBetweenExecutions` | Fixed delay between non-idle continuous-polling executions; not composed with cron schedules, `00:00:00` = disabled |
| `IdleBackoffDuration` | Replaces `DelayBetweenExecutions` after an idle continuous-polling cycle; `00:00:00` falls back to the normal continuous delay |
| `HealthSampleSize` | Rolling sample size for average calculation |
| `HealthDegradedThresholdMultiplier` | Last duration > avg x multiplier = degraded |
| `HealthHardTimeout` | Max time since last success before unhealthy |
| `ShutdownTimeout` | Graceful shutdown timeout, `TimeSpan` (default `00:00:30`) |

## Required Verification

- Validate that a five-field cron expression is rejected and a six-field expression including seconds is accepted.
- Prove a disabled worker neither runs tagged startup dependency checks nor starts its execution loop, and its service-specific health check reports healthy/disabled.
- Cover immediate, delayed-first, continuous, and run-once execution modes; `RunOnce` executes exactly once whether `RunImmediately` is true or false.
- Prove a delayed-first cron worker waits only for the cron occurrence (no pre-execution fixed delay), while continuous polling applies either the normal delay or the idle backoff, never both.
- Cover retry count as retries after the initial attempt, retry only explicitly transient exceptions, and prove exponential delay never exceeds `RetryMaxDelaySeconds`.
- Prove a non-transient failure and an exhausted transient failure are recorded, request application stop, and remain observable rather than being swallowed.
- Reject negative/zero-invalid operational settings and a retry maximum below its base delay during options validation.
- Prove startup executes only health registrations tagged `startup`, fails on degraded/unhealthy dependency checks, and never resolves the worker's own readiness check.
- Stop a running worker through `StoppingAsync` and prove cancellation interrupts schedule, idle, and execution delays.
- Await or dispose every started worker in test cleanup so faults and live loops cannot escape the test.

## Deployment Handoff

This pattern owns the application's `ShutdownTimeout`; the [`infrastructure` graceful-shutdown standard](../../infrastructure/SKILL.md#graceful-shutdown) owns Kubernetes termination grace periods and lifecycle configuration. The deployment grace period must accommodate both the host and worker shutdown budgets. Do not copy Kubernetes manifests into this service pattern.
