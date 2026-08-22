---
applyTo: "**/*.cs"
---

# C# Instructions

This file is the canonical authority for C# implementation conventions.

## Symbol-derived string identifiers

When a string identifier is intentionally the exact name of an available C# symbol, derive it from that symbol
instead of duplicating the name in a string literal.

- Use `nameof(...)` when the required value is a simple type, member, parameter, namespace segment, or other
  symbol name.
- Compose qualified or otherwise composite identifiers from those symbol-derived parts instead of repeating
  available symbol segments as text.
- Use `typeof(T).Namespace`, `typeof(T).FullName`, or `typeof(T).Assembly` metadata when that metadata is the
  actual identity contract and a `nameof(...)` composition cannot express it correctly. Handle nullable metadata
  explicitly.
- Apply this rule to configuration identifiers, `EventId` names, logging identifiers, and `ActivitySource` or
  `Meter` identities when those values are defined by CLR symbols.
- Keep an explicit literal when the value is deliberately independent of CLR naming, such as a route, protocol
  value, serialized field, semantic telemetry name, or deployment-owned resource identity. Document a
  non-obvious exception.

## Concurrency and async

- Assume multithreaded execution.
- Use async I/O end-to-end and do not block asynchronous paths.
- Require `CancellationToken` on every public asynchronous API and propagate requested cancellation.

## Exceptions and API errors

- Define domain, transient, and fatal exception categories.
- Never swallow exceptions or use a catch-all without rethrowing.
- Map HTTP API errors to `ProblemDetails`.

## Performance, nullability, and immutable data

- Profile before optimizing, remove synchronous I/O, and reduce measured allocations.
- Avoid LINQ in hot paths unless measurement supports it.
- Enable nullable reference types.
- Prefer immutable records for DTOs and value objects.

## Persistence and caching

- Use EF Core with an explicit tracking strategy.
- Use `IDistributedCache` for caches shared across process instances.

## Configuration and dependency injection

- Application-owned registration and mapping extension APIs (`Add*` and `Map*`) do not accept
  `IConfiguration` or `IConfigurationSection`.
- Bind runtime options with `BindConfiguration`.
- When feature selection shapes the DI graph before the provider exists, bind one strongly typed composition
  snapshot at the deployable runner's composition root and pass that snapshot through registration and mapping.
- A deployable runner's composition root may pass configuration to a framework or third-party composition API
  whose contract requires it, but must not relay raw configuration through an application-owned cascade.
- Never build a temporary service provider.

## APIs, time, money, and serialization

- Document business and service HTTP APIs with OpenAPI and version their routes.
- Use idempotency keys for applicable POST operations.
- Use `DateTimeOffset` at application boundaries and UTC for storage.
- Use `decimal` for money and culture-invariant parsing.
- Use System.Text.Json source generation, stable serialized field names, and backward-compatible DTO changes.

### Deployable-process HTTP endpoints

The application Host owns these deliberately unversioned process endpoints. They are thin runner behavior,
not a service, module, domain capability, or substitute for operational health probes:

- `GET /ping` allows anonymous access and returns HTTP 200 with content type `text/plain` and the exact body
  `pong`. Keep it dependency-free and domain-free. Add future response behavior only when it is deliberately
  part of this process contract; do not turn it into a readiness probe.
- `GET /me` requires the real application authentication and authorization pipeline. An unauthenticated call
  returns HTTP 401. An authenticated call returns a deliberately bounded current-user projection with stable
  identity fields such as `subject` and `name`; never return the access token or an unfiltered claim dump.

The Gateway may proxy these Host endpoints but does not duplicate their implementation. Operational liveness,
readiness, and startup behavior remains owned by the
[`Health Probes`](../skills/infrastructure/SKILL.md#health-probes) contract.

For observability implementation, see
[`OpenTelemetry Patterns`](../skills/observability/SKILL.md#opentelemetry-patterns).

## SQL in C# Code

**Do not generate dynamic SQL strings in C# code.** Use embedded SQL resources instead.

Embedded SQL placement and filenames come from
[`Canonical embedded SQL structure`](../skills/solution-structure/SKILL.md#canonical-embedded-sql-structure).
Follow
[`Resources/SQL/`](../skills/dotnet-service-generator/references/standard-service.md#resourcessql)
for the C# loader and project-file embedding implementation. On the C# side additionally:

1. Use parameterized execution with `sp_executesql` or `SqlParameter`
2. Include a `bool debug = false` parameter in `SqlParameterBuilder` methods (the SQL-side debug pattern is defined in the SQL instructions)

### SqlParameterBuilder Pattern

Parameter builders should include an optional debug flag that passes through to the SQL script:

```csharp
public static SqlParameter[] BuildParameters(
    string schemaName,
    string tableName,
    bool debug = false)  // Enables SQL debug mode
{
    return
    [
        new SqlParameter("@p0", SqlDbType.NVarChar, 128) { Value = schemaName },
        new SqlParameter("@p1", SqlDbType.NVarChar, 128) { Value = tableName },
        new SqlParameter("@p2", SqlDbType.Bit) { Value = debug }
    ];
}
```

This allows unit tests or debugging sessions to see generated SQL without execution.

### Reference Implementation

[Ruya.EntityFrameworkCore.SqlServer's BatchLock implementation](https://github.com/cilerler/ruya/tree/main/src/Ruya.EntityFrameworkCore.SqlServer/BatchLock) is the reference end-to-end example — embedded SQL, debug mode, lazy resource loading, and constants.

### Benefits

- SQL syntax highlighting and validation in editors
- Proper code review of SQL changes (not hidden in C# strings)
- Separation of concerns (SQL logic vs C# orchestration)
- Debug mode for testing without execution
- Consistent pattern across the codebase
