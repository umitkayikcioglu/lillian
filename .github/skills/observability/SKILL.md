---
name: observability
description: Standard SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns for .NET services. Use when working on dashboards, metrics, tracing, alerting, SLIs, or any observability concern.
type: guidance
applies_to:
  - Architect
  - Developer
mandatory: conditional
mandatory_when:
  - Defining SLIs or observability requirements
  - Creating dashboards or alerts
  - Instrumenting with OpenTelemetry
triggers:
  - dashboard
  - metrics
  - tracing
  - alerting
  - SLI
  - observability
references:
  - templates/grafana-dashboard.md
summary: Standard SLIs, dashboard templates, alert conventions, and OpenTelemetry patterns for .NET services.
---

# Observability Skill

Defines observability standards for .NET services including SLIs, dashboards, alerts, and instrumentation patterns.

## Roles

- **Architect**: Defines observability requirements in technical design
- **Developer**: Implements per Architect's specifications

---

## Standard SLIs

### API / HTTP Services

| SLI | Description | Target | Measurement |
|-----|-------------|--------|-------------|
| Latency p50 | Median response time | < 100ms | Histogram quantile |
| Latency p95 | 95th percentile response time | < 500ms | Histogram quantile |
| Latency p99 | 99th percentile response time | < 1000ms | Histogram quantile |
| Error Rate | 5xx responses / total requests | < 0.1% | Counter ratio |
| Availability | Successful health checks / total | > 99.9% | Uptime probe |
| Saturation | CPU/Memory utilization | < 80% | Resource metrics |
| Throughput | Requests per second | Service-specific | Counter rate |

### Scheduled / Polling Workers

| SLI | Description | Target | Measurement |
|-----|-------------|--------|-------------|
| Execution Duration p50 | Median execution time | Service-specific | Histogram quantile |
| Execution Duration p95 | 95th percentile execution time | < 2× average | Histogram quantile |
| Failure Rate | Failed executions / total | < 1% | Counter ratio |
| Retry Rate | Retries / total executions | < 5% | Counter ratio |
| Availability | Successful health checks / total | > 99.9% | Uptime probe |
| Saturation | CPU/Memory utilization | < 80% | Resource metrics |

### Message Consumers

Long-lived broker subscribers use delivery-oriented signals rather than scheduled execution signals.

| SLI | Description | Target | Measurement |
|-----|-------------|--------|-------------|
| Processing Duration p95 | 95th percentile handler duration | Service-specific | Histogram quantile |
| Unhandled Rate | Delivery attempts ending in an unhandled error / total delivery attempts | < 1% | Queue-implementation counter ratio |
| Retry Rate | Retried deliveries / total deliveries | < 5% | Counter ratio |
| Reject Rate | Permanently rejected delivery attempts / total delivery attempts | < 0.1% | Queue-implementation counter ratio |
| DLQ Ingress Rate | Messages entering the dead-letter queue | Service-specific | Broker/exporter counter rate |
| Queue Age | Age of the oldest available message | Service-specific | Broker/exporter gauge |
| Queue Depth | Messages waiting to be processed | Service-specific | Broker/exporter gauge |
| Subscription Availability (when supported) | Healthy active subscriptions / expected subscriptions | > 99.9% | Queue-implementation health signal |

---

## Alert Thresholds

### Severity Levels

| Severity | Response | Examples |
|----------|----------|----------|
| **Critical** | Immediate page | Service down, data loss risk, SLA breach |
| **Warning** | Review within hours | Degraded performance, approaching limits |
| **Info** | Review next business day | Anomalies, capacity planning signals |

### Standard Thresholds

| Metric | Warning | Critical | For Duration |
|--------|---------|----------|--------------|
| Error rate | > 1% | > 5% | 5 min / 2 min |
| Latency p95 | > 1s | > 3s | 5 min / 2 min |
| Latency p99 | > 2s | > 5s | 5 min / 2 min |
| CPU usage | > 70% | > 90% | 10 min / 5 min |
| Memory usage | > 75% | > 90% | 10 min / 5 min |
| Queue depth | > 1000 | > 5000 | 5 min / 2 min |
| Queue age (oldest msg) | > 5 min | > 15 min | 5 min / 2 min |
| Health check failures | 1 failure | 3 consecutive | immediate / 1 min |
| Connection pool exhaustion | > 80% | > 95% | 5 min / 2 min |
| Worker execution failure rate | > 10% | > 25% | 5 min / 2 min |
| Worker retry rate | > 10/min | > 50/min | 5 min / 2 min |
| Worker execution duration p95 | > 2× avg | > 5× avg | 5 min / 2 min |
| Message consumer unhandled rate | > 1% | > 5% | 5 min / 2 min |
| Message consumer retry rate | > 5% | > 15% | 5 min / 2 min |
| Message reject rate | > 0.1% | > 1% | 5 min / 2 min |
| Subscription availability (when supported) | Below expected count | Zero active subscriptions | 1 min / immediate |

---

## Dashboard Templates

See [templates/grafana-dashboard.md](templates/grafana-dashboard.md) for Grafana JSON starting points and query examples.

### Generation Rules

This section is the single canonical home of all dashboard generation rules.

1. **Owner scope and placement**: Use a scope and path permitted by
   [`Canonical Grafana dashboard placement`](../solution-structure/SKILL.md#canonical-grafana-dashboard-placement).
   This skill does not restate the scope list or paths.
2. **Optional at every scope**: Generate a dashboard only when concrete operational requirements and useful,
   supported panels exist at that scope. Do not create empty dashboards or duplicate a narrower dashboard at
   broader scopes merely to populate every possible location. A single useful panel is sufficient.
3. **Environment variable**: Every generated dashboard must include an `env` query variable populated from the Prometheus `env` label. Do not enumerate environment names in the dashboard; deployments own the available `ASPNETCORE_ENVIRONMENT` values.
4. **Datasource variable**: Every generated dashboard must include the `$datasource` template variable.
5. **Service variable**: A dashboard that queries service-emitted telemetry must include a `$service` query variable populated from a guaranteed series for that workload; do not assume an HTTP series. A broker-only dashboard omits `$service` unless an explicit mapping attributes the broker series to a service.
6. **Query filtering**: Queries over service-emitted telemetry include `env="$env"` and `service_name="$service"`. Broker/exporter queries use the selected provider's documented environment and destination/subscription labels. If those labels cannot map a broker series unambiguously to a service, add an explicit relabeling or recording-rule mapping before generating the panel; do not apply nonexistent service resource labels.
7. **Dashboard identity placeholders**: Use `$(DASHBOARD_SUBJECT_NAME)` in the title for the complete canonical
   identity of the monitored scope resolved from `solution-structure`. Use `$(DASHBOARD_UID)` only for
   Grafana's separate stable, provider-safe dashboard identifier.
   The UID is a technical identifier, not a shortened second form of the subject name; deployment tooling must
   replace both placeholders.
8. **Tags**: Include the `generated` tag on all dashboards.
9. **Worker metric naming**: Resolve the authoring token `{WorkerSnakeName}` once by converting the complete
   `{ServiceName}Worker` class name to snake_case. For example, `PaymentProcessorWorker` becomes
   `payment_processor_worker`. The placeholder name is PascalCase even though its resolved value is snake_case.
   `WorkerBackgroundService` emits `app_{WorkerSnakeName}_{metric}`; the `_worker` suffix is therefore part of
   every worker metric prefix.
10. **Polylith service identity**: `service.name` / Prometheus `service_name` identifies the deployable process,
   not an internal module service. Generated custom instruments use the bounded
   `app_{ServiceSnakeName}_*` prefix, where `{ServiceSnakeName}` is the canonical snake_case token resolved by
   [`dotnet-service-generator`](../dotnet-service-generator/SKILL.md#step-1-gather-basic-info). Internal spans may use the bounded
   `app.service.name` attribute. Never overwrite the resource `service.name` from inside a module. A
   service-scoped dashboard filters the process with `$service` and selects that internal service's instrument
   prefix.

### Service Health Dashboard

Candidate panels; select only those backed by the dashboard's operational purpose and available telemetry:
1. **Request Rate** - req/s over time
2. **Error Rate** - % errors with breakdown by status code
3. **Latency Histogram** - p50, p95, p99 percentiles
4. **Active Connections** - Current connection count
5. **Health Check Status** - Liveness and readiness state
6. **Instance Count** - Number of running replicas

### API Performance Dashboard

Candidate panels; select only those backed by the dashboard's operational purpose and available telemetry:
1. **Endpoint Latency Breakdown** - Latency by endpoint
2. **Top 10 Slowest Endpoints** - Sorted by p95 latency
3. **Error Breakdown by Status Code** - 4xx vs 5xx distribution
4. **Request Volume by Endpoint** - Traffic distribution
5. **Request Duration Heatmap** - Time vs latency visualization

### Background Worker Dashboard

Candidate panels for services extending `WorkerBackgroundService<TSettings>`; select only those backed by the
dashboard's operational purpose and available telemetry:
1. **Execution Rate** - Executions per second over time
2. **Success / Failure Ratio** - Stacked success vs failed executions
3. **Active Executions** - Currently running executions gauge
4. **Retry Rate** - Retry attempts over time
5. **Execution Duration** - p50, p95, p99 percentiles from histogram

### Message Consumer Dashboard

Candidate panels for long-lived broker subscribers; select only those backed by the dashboard's operational
purpose and available telemetry:
1. **Consume Rate** - Deliveries processed per second
2. **Success / Retry / Reject / Unhandled Ratio** - Mutually exclusive delivery-attempt outcomes over time
3. **Processing Duration** - p50, p95, p99 handler duration
4. **Queue Depth and Oldest Message Age** - Backlog volume and staleness
5. **DLQ Ingress and Depth** - Messages entering the dead-letter queue and messages awaiting action
6. **Subscription Health** - Expected versus active/healthy subscriptions, when the implementation supplies both values

Telemetry ownership is intentionally split:

- The selected message-queue implementation owns transport spans, context propagation, processing duration,
  mutually exclusive delivery-attempt outcomes (`success`, `retry`, `reject`, or `unhandled`), and
  subscription-health signals.
- The broker or its exporter owns queue depth, oldest-message age, and DLQ ingress/depth.
- The service owns only business-specific telemetry; it does not duplicate transport metrics or consumer spans already emitted by the queue implementation.

The queue instrumentation boundary must observe serialization/deserialization, handler completion, returned
delivery results, and broker settlement. A delivery attempt completes only after its broker-facing result is
applied; decode, middleware, handler, or settlement failure is `unhandled` exactly once. A host-requested
cancellation is incomplete: emit neither an outcome nor duration and do not settle it as poison. Publisher
instrumentation injects trace context into the envelope and consumer instrumentation extracts it. An
implementation-level telemetry switch must actually enable or disable this instrumentation, and the
implementation must document the ActivitySource, Meter, instrument names, outcome values, and bounded labels
that an application must register with its OpenTelemetry providers.

Consumer metric labels are limited to bounded provider system, configured destination, optional configured
subscription/consumer group, and the four-value outcome. Message/correlation IDs, message types, reasons,
exception text, delivery counts, and generated consumer IDs belong only in traces or logs. Enable exactly one
producer/consumer instrumentation layer for an operation; do not collect a provider's native spans alongside a
wrapper that emits the same spans.

Before generating a dashboard, identify one guaranteed processing series for `$env` and `$service` discovery and document the provider labels that select destination, subscription, or consumer group. Do not use HTTP metrics to discover variables for a subscriber-only service. Subscription availability is required only when the selected implementation exposes a reliable active/healthy signal and an expected-count model; otherwise omit that panel and alert, record the capability gap, and do not invent a gauge.

Processing duration and mutually exclusive outcome signals are required capabilities. If the selected implementation does not document them, or its configured telemetry switch does not activate them at the actual delivery boundary, stop generation and surface the capability gap instead of inventing queries or silently duplicating transport telemetry in the service. Making the subscriber own a missing signal is an explicit design decision that transfers ownership for that signal; it is not an automatic generator fallback.

Dashboard queries use the metric names documented by the selected implementation and broker exporter. Those implementation-owned names are not copied into this provider-neutral standard. Delivery outcomes and DLQ signals stay separate: a rejected attempt may be dropped, retried by policy, or dead-lettered later, while DLQ ingress/depth describe broker state.

### Resource Usage Dashboard

Candidate panels; select only those backed by the dashboard's operational purpose and available telemetry:
1. **CPU Utilization** - Per instance over time
2. **Memory Usage** - Heap, working set, GC metrics
3. **GC Metrics** - Gen0/Gen1/Gen2 collections, pause times
4. **Thread Pool** - Worker threads, completion port threads
5. **Connection Pools** - Database, HTTP client pool saturation
6. **Disk I/O** - If applicable

---

## OpenTelemetry Patterns

Use [Ruya.OpenTelemetry](https://github.com/cilerler/ruya/blob/main/src/Ruya.OpenTelemetry/README.md) as the reference implementation for the patterns below.

### Observability Triad

All services should inject these three interfaces for complete observability:

| Interface | Purpose | Usage |
|-----------|---------|-------|
| `ILogger<T>` | Structured logging | Log events with contextual data |
| `IDistributedTracing` | Distributed tracing | Create spans/activities for operations |
| `IMeterFactory` | Metrics | Create counters, histograms, gauges |

Constructor pattern:
```csharp
public {ServiceName}Service(
    ILogger<{ServiceName}Service> logger,
    IDistributedTracing distributedTracing,
    IMeterFactory meterFactory)
```

### Log Levels

Every operation should be logged to provide a complete activity flow. Use the appropriate level:

| LogLevel | Value | When to Use |
|----------|-------|-------------|
| `Trace` | 0 | Most detailed messages. May contain sensitive data. Disabled by default; never enable in production. |
| `Debug` | 1 | Debugging and development. Use with caution in production due to high volume. |
| `Information` | 2 | General flow of the application. May have long-term value. |
| `Warning` | 3 | Abnormal or unexpected events. Errors or conditions that don't cause the app to fail. |
| `Error` | 4 | Errors and exceptions that cannot be handled. Failure in the current operation or request, not app-wide. |
| `Critical` | 5 | Failures requiring immediate attention (data loss, out of disk space). |
| `None` | 6 | Suppresses all logging for a category. |

Severity increases from Trace (lowest) to Critical (highest).

### Activity Kinds

When creating OpenTelemetry activities/spans, choose the correct `ActivityKind`:

| Kind | When to Use |
|------|-------------|
| `ActivityKind.Client` | Making a synchronous outbound call to an external system (DB, HTTP, gRPC) |
| `ActivityKind.Server` | Handling an incoming synchronous request |
| `ActivityKind.Producer` | Initiating an asynchronous request — sending a message to a queue, pub/sub topic, or event bus |
| `ActivityKind.Consumer` | Processing a message received asynchronously from a queue, pub/sub topic, or event bus |
| `ActivityKind.Internal` | In-process operation with no external call (default) |

Example:
```csharp
using var activity = _tracer.StartActivity("ProcessItem", ActivityKind.Internal);
using var dbActivity = _tracer.StartActivity("QueryDatabase", ActivityKind.Client);
```

### Registration

```csharp
// Program.cs
builder.ConfigureOpenTelemetry();
```

### Environment Attribution

The OpenTelemetry library is expected to automatically set `deployment.environment` as a resource attribute on all telemetry (metrics, traces, logs) using `builder.Environment.EnvironmentName`. This value comes from `ASPNETCORE_ENVIRONMENT`, which is supplied by the deployment.

For Prometheus-backed dashboards, the telemetry pipeline must copy `deployment.environment` to the metric data-point attribute `env`. The Prometheus exporter exposes that attribute as the `env` label used by the `$env` template variable. This mapping is explicit because resource attributes are not automatically attached to every Prometheus metric.

For traces, an activity processor should also stamp each span with `deployment.environment` as a tag.

### Configuration

```json
{
  "OpenTelemetry": {
    "Service": {
      "Name": "{DeployableProcessName}",
      "Version": "1.0.0"
    },
    "Sampling": {
      "Type": "ParentBased",
      "ParentBasedRootSampler": "TraceIdRatio",
      "Ratio": 0.1
    },
    "Http": {
      "CaptureRequestBody": false,
      "CaptureResponseBody": false,
      "MaxBodySizeBytes": 32768,
      "AllowedContentTypes": [ "application/json" ]
    },
    "Sql": {
      "RecordException": true,
      "CaptureCommandText": true,
      "SanitizeStatements": true
    }
  },
  "OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel-collector:4317"
}
```

`{DeployableProcessName}` is the deployment-owned workload/resource identity selected from the canonical
runner table in `solution-structure`: the complete Host, Gateway, or AppHost project stem. It is never an
internal modular service or a sibling standalone-service implementation project. Confirm the actual runner
from deployment configuration instead of deriving it from `{ServiceName}`.

The same complete `{DeployableProcessName}` is also the deployable project's canonical namespace. Do not add a
second namespace token or substitute the namespace of an internal modular service hosted by another process.

The value shown for `OTEL_EXPORTER_OTLP_ENDPOINT` is the documented default and a reminder of the expected OTLP gRPC endpoint shape. Deployments whose collector uses a different hostname or port must override it.

### Middleware (Optional)

Use body capture only for a concrete diagnostic requirement. It stays disabled by default, must be bounded,
and may emit only valid JSON after configured redaction; invalid, oversized, and non-JSON bodies are represented
by marker values rather than raw content. Do not use synchronous instrumentation callbacks to read asynchronous
request or response bodies.

```csharp
app.UseRouting();
app.UseHttpBodyCapture(); // Must be after UseRouting
// Map the architecture's selected API adapter after observability middleware.
```

Observability does not select `MapControllers`, Minimal API endpoint mapping, OData routing, or another API
adapter. Apply the mapping required by the selected architecture.

### Instrumentation Example

Complete example combining all three: structured logging, distributed tracing, and custom metrics.

```csharp
using System;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Ruya.Diagnostics.DistributedTracing;
using Ruya.Primitives;

public class {ServiceName}Service : IDisposable
{
    private static readonly EventId ItemProcessing = new(1000, nameof(ItemProcessing));
    private static readonly EventId ItemProcessingFailed = new(1001, nameof(ItemProcessingFailed));

    private readonly ILogger<{ServiceName}Service> _logger;
    private readonly IDistributedTracing _tracer;
    private readonly Meter _meter;
    private readonly IItemProcessor _itemProcessor;
    private readonly Counter<long> _itemsProcessed;
    private readonly Histogram<double> _processingDuration;

    public {ServiceName}Service(
        ILogger<{ServiceName}Service> logger,
        IDistributedTracing distributedTracing,
        IMeterFactory meterFactory,
        IItemProcessor itemProcessor)
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
        _itemProcessor = itemProcessor;

        _itemsProcessed = _meter.CreateCounter<long>(
            "app_{ServiceSnakeName}_items_processed",
            unit: "{item}",
            description: "Number of items processed");

        _processingDuration = _meter.CreateHistogram<double>(
            "app_{ServiceSnakeName}_processing_duration",
            unit: "ms",
            description: "Time to process an item");
    }

    public async Task ProcessAsync(Item item, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        using var activity = _tracer.StartActivity("ProcessItem");
        activity.SetTag("app.service.name", nameof({ServiceName}Service));
        activity.SetTag("item.id", item.Id);
        activity.SetTag("item.type", item.Type);
        var sw = Stopwatch.StartNew();

        try
        {
            _logger.LogDebug(ItemProcessing, "Processing item {ItemId}", item.Id);
            await _itemProcessor.ProcessAsync(item, cancellationToken);
            _itemsProcessed.Add(1, new TagList { { "status", "success" } });
            activity.SetStatus(ActivityStatusCode.Ok);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _itemsProcessed.Add(1, new TagList { { "status", "failure" } });
            activity.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity.SetTag("exception.type", ex.GetType().FullName);
            activity.SetTag("exception.message", ex.Message);
            _logger.LogError(ItemProcessingFailed, ex, "Failed to process item {ItemId}", item.Id);
            throw;
        }
        finally
        {
            _processingDuration.Record(sw.ElapsedMilliseconds);
        }
    }

    public void Dispose()
    {
        _meter.Dispose();
        GC.SuppressFinalize(this);
    }
}
```

### Semantic Conventions

Use OpenTelemetry semantic conventions for tag names:

| Category | Convention | Example |
|----------|------------|---------|
| HTTP | `http.request.method`, `http.response.status_code`, `url.full` | `http.request.method=POST` |
| Database | `db.system`, `db.namespace`, `db.query.text` | `db.system=mssql` |
| Messaging | `messaging.system`, `messaging.destination.name` | `messaging.system=rabbitmq` |
| Exception | `exception.type`, `exception.message` | `exception.type=InvalidOperationException` |

---

## Architect Checklist

When defining observability requirements in technical design:

1. [ ] Which SLIs matter for this service?
2. [ ] What are the target values for each SLI?
3. [ ] Would a dashboard at any valid owner scope provide useful, non-duplicated panels? If so, which panels?
4. [ ] What alert conditions and thresholds apply?
5. [ ] What custom metrics are needed?
6. [ ] What traces should be captured?
7. [ ] What log levels and structured fields are required?

---

## Developer Checklist

When implementing observability:

1. [ ] OpenTelemetry configured via `ConfigureOpenTelemetry()`
2. [ ] Deployable process name, namespace, and version set in configuration
3. [ ] Custom metrics created per Architect's requirements
4. [ ] Critical operations have traces with appropriate tags
5. [ ] Structured logging with event IDs for significant operations
6. [ ] Grafana dashboard JSON created when concrete, non-duplicated panels are required
7. [ ] Alert rules configured
8. [ ] Runbook draft includes observability section
