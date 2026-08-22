# API Patterns

## Select the API Adapter

Select an API adapter from the confirmed consumer boundary; `Api/` is not synonymous with one transport:

| Consumer / interaction | Canonical adapter |
|---|---|
| In-process caller | Producer-owned `I{ServiceName}` contract; no HTTP loopback |
| Synchronous caller in another deployment | Versioned Minimal API |
| UI data and query client | OData controller and composed EDM |
| Asynchronous caller in another deployment | Producer-owned message contract and messaging adapter |

Minimal API and OData are first-class, deliberately different adapters. A service may select both for
different consumers, but both remain thin and call the same `I{ServiceName}` business boundary. Never place
business rules or direct persistence mutations in an endpoint or controller. Protocol authorization metadata
may live on the adapter; the service still enforces mandatory domain and data-scope rules. The service owns
business behavior and persistence interaction.

## Versioned Minimal API Adapter (Cross-Deployment Machine API)

Use the `Api/` folder with a route group definition and separate endpoint files.

## File Structure

```
Api/
├── {ServiceName}Api.cs        # Route group definition, shared middleware
├── GetAllEndpoint.cs
├── GetByIdEndpoint.cs
├── CreateEndpoint.cs
├── UpdateEndpoint.cs
└── DeleteEndpoint.cs
```

> **Error handling**: Unhandled exceptions flow to the centralized exception-handling middleware, which maps them to ProblemDetails responses. Endpoints catch only expected, actionable exceptions (for example, `{ServiceName}ValidationException` maps to validation ProblemDetails with HTTP 400) — never `catch (Exception)`.

When versioned Minimal API CRUD exposure is selected, generate `Create{ServiceName}Request` and
`Update{ServiceName}Request` at the selected request-contract boundary, use the response contract from its
selected response-contract boundary, and replace the neutral `I{ServiceName}.DoWorkAsync` placeholder with
the operations used by these endpoints:

The `GetAll` variant below is allowed only when the domain collection has a small, enforced upper bound.
For an unbounded collection, select the application's canonical cursor/page contract during discovery and
generate `GetPageAsync` plus bounded query parameters instead; do not copy the unbounded operation.

Merge these imports into the existing `I{ServiceName}.cs` at the selected service-contract boundary.
`Contracts/I{ServiceName}.cs` is only the default service-internal path; do not create or update a second
copy there after the interface has moved to an `Abstractions/Interfaces` boundary.

```csharp
using System;
using System.Collections.Generic;
using {RequestContractNamespace};
using {ResponseContractNamespace};
```

```csharp
Task<IReadOnlyList<{ServiceName}Response>> GetAllAsync(CancellationToken cancellationToken);
Task<{ServiceName}Response?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
Task<{ServiceName}Response> CreateAsync(Create{ServiceName}Request request, CancellationToken cancellationToken);
Task<{ServiceName}Response?> UpdateAsync(Guid id, Update{ServiceName}Request request, CancellationToken cancellationToken);
Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken);
```

The corresponding request contracts are service-named so multiple capabilities can share one abstractions
project without type collisions. Place each file under the selected producer boundary's `Requests/` role
folder. `Abstractions/Requests/` beneath `{ServiceRoot}` is only the default service-boundary path; when
`{RequestContractNamespace}` resolves elsewhere, move the file and namespace together.

### Requests/Create{ServiceName}Request.cs at the selected request-contract boundary

```csharp
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Create{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

### Requests/Update{ServiceName}Request.cs at the selected request-contract boundary

```csharp
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Update{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

Public request/response members keep explicit `JsonPropertyName` values so CLR refactoring cannot silently
change the wire contract.

## {ServiceName}Service.cs additions

Implement every selected API operation on `{ServiceName}Service` with the exact interface signatures above.
The service owns input validation, mapping, persistence/external dependency calls, and domain exception
classification; endpoint files only bind HTTP input, invoke the service, and map expected outcomes. Generate
the concrete implementation from the confirmed domain behavior and selected dependencies. If that behavior is
not known, stop and ask—do not emit `NotImplementedException`, `default`, an in-memory fake, or business logic
inside an endpoint merely to make the scaffold compile.

## Api/{ServiceName}Api.cs

Route group definition and endpoint registration:

```csharp
namespace {ServiceNamespace}.Api;

using Microsoft.AspNetCore.Builder;

internal static class {ServiceName}Api
{
    internal static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/v1/{ServiceKebabName}")
           .WithTags("{ServiceName}")
           .WithOpenApi()
           .MapGetAll()
           .MapGetById()
           .MapCreate()
           .MapUpdate()
           .MapDelete();

        return app;
    }
}
```

`Map{ServiceName}Api` is assembly-internal so Host cannot bypass the owning service's feature and DI gate.
Only `Extensions/StartupExtensions.Map{ServiceName}Service` calls this low-level mapper.

## Api/GetAllEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ResponseContractNamespace};
using {ServiceContractNamespace};

public static class GetAllEndpoint
{
    public static RouteGroupBuilder MapGetAll(this RouteGroupBuilder group)
    {
        group.MapGet("/", async (
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.GetAllAsync(cancellationToken);
            return Results.Ok(result);
        })
        .WithName("GetAll{ServiceName}")
        .Produces<IReadOnlyList<{ServiceName}Response>>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/GetByIdEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ResponseContractNamespace};
using {ServiceContractNamespace};

public static class GetByIdEndpoint
{
    public static RouteGroupBuilder MapGetById(this RouteGroupBuilder group)
    {
        group.MapGet("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.GetByIdAsync(id, cancellationToken);
            return result is null 
                ? Results.NotFound() 
                : Results.Ok(result);
        })
        .WithName("Get{ServiceName}ById")
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/CreateEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public static class CreateEndpoint
{
    public static RouteGroupBuilder MapCreate(this RouteGroupBuilder group)
    {
        group.MapPost("/", async (
            [FromBody] Create{ServiceName}Request request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.CreateAsync(request, cancellationToken);
                return Results.Created($"/api/v1/{ServiceKebabName}/{result.Id}", result);
            }
            catch ({ServiceName}ValidationException e)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["request"] = [.. e.Errors]
                });
            }
        })
        .WithName("Create{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status201Created)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/UpdateEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public static class UpdateEndpoint
{
    public static RouteGroupBuilder MapUpdate(this RouteGroupBuilder group)
    {
        group.MapPut("/{id:guid}", async (
            Guid id,
            [FromBody] Update{ServiceName}Request request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.UpdateAsync(id, request, cancellationToken);
                return result is null 
                    ? Results.NotFound() 
                    : Results.Ok(result);
            }
            catch ({ServiceName}ValidationException e)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["request"] = [.. e.Errors]
                });
            }
        })
        .WithName("Update{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/DeleteEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ServiceContractNamespace};

public static class DeleteEndpoint
{
    public static RouteGroupBuilder MapDelete(this RouteGroupBuilder group)
    {
        group.MapDelete("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var success = await service.DeleteAsync(id, cancellationToken);
            return success 
                ? Results.NoContent() 
                : Results.NotFound();
        })
        .WithName("Delete{ServiceName}")
        .Produces(StatusCodes.Status204NoContent)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Serialization/{ServiceName}JsonSerializerContext.cs

API DTOs use System.Text.Json source generation. This is the HTTP adapter's service-owned context: it always
stays at `{ServiceRoot}/Serialization/{ServiceName}JsonSerializerContext.cs` with namespace
`{ServiceNamespace}.Serialization`, even when one or more DTO declarations move to a broader contract
boundary. Import the resolved contract namespaces; never copy the DTOs back into the service merely to keep
this context local.

The file below is the CRUD branch. Include every concrete request, response, collection, and event type that
the selected API serializes; do not rely on reflection fallback or retain types from an unselected branch.
This adapter context does not replace a reusable producer-owned context required by the selected contract
boundary or another transport. Such a contract-owned context stays beside its contracts at that producer
boundary and moves, with its namespace and project references, whenever those contracts move.

```csharp
namespace {ServiceNamespace}.Serialization;

using System.Collections.Generic;
using System.Text.Json.Serialization;
using {RequestContractNamespace};
using {ResponseContractNamespace};

[JsonSerializable(typeof(Create{ServiceName}Request))]
[JsonSerializable(typeof(Update{ServiceName}Request))]
[JsonSerializable(typeof({ServiceName}Response))]
[JsonSerializable(typeof(IReadOnlyList<{ServiceName}Response>))]
[JsonSerializable(typeof(List<{ServiceName}Response>))]
internal partial class {ServiceName}JsonSerializerContext : JsonSerializerContext
{
}
```

When the versioned Minimal API adapter is selected, add this registration to `Add{ServiceName}Service`:

```csharp
// StartupExtensions.cs import
using {ServiceNamespace}.Serialization;

// Inside Add{ServiceName}Service
services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.TypeInfoResolverChain.Insert(
        0,
        {ServiceName}JsonSerializerContext.Default));
```

## Registration in Program.cs

```csharp
// `capabilities` is the strongly typed Host composition snapshot bound in Program.cs.
builder.Services.AddConfiguredCapabilities(capabilities);

var app = builder.Build();

app.MapConfiguredEndpoints();
```

Use the matching registration and mapping cascade from
[`modular-polylith.md`](modular-polylith.md#registration-chain).
The public service wrapper receives the captured route decision from that cascade and maps only after
confirming `I{ServiceName}` is registered. It never re-reads live configuration. The low-level
`Map{ServiceName}Api` method remains service-owned and internal.

## HTTP Test Files

When API endpoints are created, generate their `.http` test file at the complete `{TestTarget}.http` path
resolved from [`Canonical test project and HTTP file naming`](../../solution-structure/SKILL.md#canonical-test-project-and-http-file-naming).
`{TestTarget}` is the full canonical target selected there; never replace it with a service-only, component-only,
module-only, or `App` basename. The following is the file content example:

```http
@baseUrl = https://localhost:5001
@contentType = application/json
@id = 00000000-0000-0000-0000-000000000001

###
# Get all {ServiceName} items
# @name GetAll
GET {{baseUrl}}/api/v1/{ServiceKebabName}
Accept: {{contentType}}

###
# Get a specific {ServiceName} by ID
# @name GetById
GET {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
Accept: {{contentType}}

###
# Create a new {ServiceName}
# @name Create
POST {{baseUrl}}/api/v1/{ServiceKebabName}
Content-Type: {{contentType}}

{
  "data": "sample-data"
}

###
# Update an existing {ServiceName}
# @name Update
PUT {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
Content-Type: {{contentType}}

{
  "data": "updated-data"
}

###
# Delete a {ServiceName}
# @name Delete
DELETE {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
```

## Single Action Pattern

For services with one primary action, use the same folder structure with fewer endpoints:

Generate `Execute{ServiceName}Request` in the selected request-contract boundary's `Requests/` role folder,
use the service response contract, and replace the neutral interface operation with the one consumed by the
endpoint. `{ServiceRoot}/Abstractions/Requests/Execute{ServiceName}Request.cs` is only the default
service-boundary path.

```csharp
// Existing I{ServiceName}.cs at the selected service-contract boundary
using {RequestContractNamespace};
using {ResponseContractNamespace};
```

```csharp
Task<{ServiceName}Response> ExecuteAsync(
    Execute{ServiceName}Request request,
    CancellationToken cancellationToken);
```

```csharp
// Requests/Execute{ServiceName}Request.cs at the selected request-contract boundary
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Execute{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

For this branch, generate the service-owned API adapter context at the same `Serialization/` path and
namespace defined above, with exactly its selected wire types. Any producer-owned contract context remains at
the selected contract boundary; neither context changes the DTO declaration's ownership.

```csharp
namespace {ServiceNamespace}.Serialization;

using System.Text.Json.Serialization;
using {RequestContractNamespace};
using {ResponseContractNamespace};

[JsonSerializable(typeof(Execute{ServiceName}Request))]
[JsonSerializable(typeof({ServiceName}Response))]
internal partial class {ServiceName}JsonSerializerContext : JsonSerializerContext
{
}
```

```
Api/
├── {ServiceName}Api.cs
└── ExecuteEndpoint.cs
```

```csharp
namespace {ServiceNamespace}.Api;

using Microsoft.AspNetCore.Builder;

internal static class {ServiceName}Api
{
    internal static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/v1/{ServiceKebabName}")
           .WithTags("{ServiceName}")
           .WithOpenApi()
           .MapExecute();

        return app;
    }
}
```

```csharp
namespace {ServiceNamespace}.Api;

using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};

public static class ExecuteEndpoint
{
    public static RouteGroupBuilder MapExecute(this RouteGroupBuilder group)
    {
        group.MapPost("/execute", async (
            [FromBody] Execute{ServiceName}Request request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.ExecuteAsync(request, cancellationToken);
            return Results.Ok(result);
        })
        .WithName("Execute{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## OData Controller Adapter (UI Data and Query Surface)

Select OData when a UI needs a discoverable entity model and composable data/query behavior. ASP.NET Core
OData routing is controller-based: generate one `{EntitySetName}Controller` per deliberately exposed entity
set in the owning service's `Api/` folder and preserve the exact entity-set identity in the EDM, controller,
route conventions, and tests. OData is not a second business implementation. Controllers translate the
protocol and delegate writes and non-query behavior to `I{ServiceName}`; they do not inject `DbContext`, call
`SaveChanges`, or implement domain decisions.

### Required OData semantics

During discovery, confirm and then preserve each selected semantic rather than generating generic CRUD:

- `$metadata` describes every exposed entity set, complex type, navigation, function, action, key, and
  concurrency token required by the UI contract.
- Enable only the agreed query options (`$select`, `$filter`, `$orderby`, `$expand`, `$count`, and paging).
  Apply `[EnableQuery]` only to actions intended to be composable, retain `IQueryable<T>` until the selected
  provider translates it, and enforce query validation and finite limits.
- Preserve every required cross-entity `$expand` path in the EDM and verify it against the backing query
  provider. Do not materialize first and accidentally move an unbounded query into memory.
- Configure both client-driven limits (`SetMaxTop`) and server-driven paging (`[EnableQuery(PageSize = ...)]`)
  where selected. Verify the continuation/next-link behavior; `SetMaxTop` alone is not server paging.
- Mark every selected optimistic-concurrency property as an EDM concurrency token. Mutations honor
  `If-Match`, reject a stale ETag with the selected precondition response, and keep the EF/domain concurrency
  rule aligned with the EDM rule.
- When `$batch` is selected, pass a batch handler to `AddRouteComponents` and call `UseODataBatching` before
  routing. Preserve batch quotas, transaction/change-set behavior, and partial-failure semantics defined by
  the application; do not assume batching is enabled merely because OData is registered.
- Preserve selected functions and actions in the owning EDM contribution and keep their side-effect semantics
  honest: functions are query/read operations; commands with side effects are actions.

### EDM ownership and composition

Do not make Host the author of the data model. The boundary that owns an entity or behavior owns a complete,
descriptively named `ODataConventionModelBuilder` contribution extension:

- a selected shared `Data` project contributes shared persistence entity sets and concurrency metadata;
- a module contributes module-owned entity sets, complex types, functions, and actions;
- a component contributes component-owned model elements; and
- a service may contribute service-private model elements when neither broader boundary owns them.

Use complete contribution names: `Add{ModuleName}ModuleEdmContributions`,
`Add{ComponentName}ComponentEdmContributions`, and `Add{ServiceName}ServiceEdmContributions`. As with DI
registration, a module contribution calls its component contributions and a component contribution calls its
service contributions; the runner invokes only the selected top-level module contributions rather than
skipping directly to descendants. Generate a contribution method only where that boundary actually owns or
aggregates OData model elements.

Resolve every contribution file through the
[canonical solution structure](../../solution-structure/SKILL.md#net-solution-folder-structure). The selected
shared `Data` contribution uses this implementation shape:

```csharp
namespace {Organization}.{Product}.Data;

using System;
using Microsoft.OData.ModelBuilder;
using {Organization}.{Product}.Models.{DatabaseName};

public static class ODataExtensions
{
    public static ODataConventionModelBuilder Add{DatabaseName}EntitySets(
        this ODataConventionModelBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        // Add only entity sets and concurrency metadata deliberately owned by the shared model.
        builder.EntitySet<{EntityTypeName}>("{EntitySetName}");
        return builder;
    }
}
```

Module, component, and service contribution files use the same complete extension shape, add only their
confirmed model elements, and call the next level's selected contribution methods. When a component or
service has an independent gate, its parent contribution accepts the explicitly named captured Boolean and
calls that child contribution only when enabled. It never accepts the runner-owned `CapabilitySelection`
type. `{EntityTypeName}` and `{EntitySetName}` are gathered per
exposed entity set; substitute their actual CLR and EDM identities rather than copying the sample as a one-set
implementation.

For this module/standalone-service OData branch, the deployable runner performs composition only: it creates
one builder, invokes only the contributions from the capabilities selected in its immutable snapshot, builds
one EDM for the selected OData route, and configures MVC/OData. Module-level selection may add or remove that module assembly as an MVC application
part. Component/service selection cannot use application-part removal because those controllers share the
module assembly: when a child OData gate exists, register a controller-feature convention at composition time
from the same immutable snapshot so actions on a disabled child are not candidates. Never implement a child
gate by returning 404 from an already-routable controller, and do not duplicate an entity set in multiple
contributions.

The runner's structure-selected controller feature provider contains no business behavior:

```csharp
namespace {Organization}.{Product}.Host.Configuration;

using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.ApplicationParts;
using Microsoft.AspNetCore.Mvc.Controllers;

internal sealed class CapabilityControllerFeatureProvider(
    IEnumerable<Type> disabledControllerTypes)
    : IApplicationFeatureProvider<ControllerFeature>
{
    private readonly HashSet<Type> _disabledControllerTypes = new(disabledControllerTypes);

    public void PopulateFeature(IEnumerable<ApplicationPart> parts, ControllerFeature feature)
    {
        for (var index = feature.Controllers.Count - 1; index >= 0; index--)
        {
            if (_disabledControllerTypes.Contains(feature.Controllers[index].AsType()))
            {
                feature.Controllers.RemoveAt(index);
            }
        }
    }
}
```

After `AddControllers()`, append that provider to the application-part manager using the exact controller
types owned by independently disabled children. A controller type may be public for MVC discovery and Host
composition without becoming a public application contract:

```csharp
var disabledODataControllers = new List<Type>();
if (!capabilities.{ServiceName})
{
    disabledODataControllers.Add(typeof({EntitySetName}Controller));
}

mvcBuilder.ConfigureApplicationPartManager(parts =>
    parts.FeatureProviders.Add(
        new CapabilityControllerFeatureProvider(disabledODataControllers)));
```

List every controller owned by the disabled child. The matching module/component EDM contribution cascade
receives the same captured Boolean and omits that child's entity sets, functions, actions, and complex types.

```csharp
var edmBuilder = new ODataConventionModelBuilder();
edmBuilder.Add{DatabaseName}EntitySets();

if (capabilities.{ModuleName})
{
    edmBuilder.Add{ModuleName}ModuleEdmContributions(
        serviceNameEnabled: capabilities.{ServiceName});
}

builder.Services
    .AddControllers()
    .AddOData(options =>
    {
        options
            .Select()
            .Filter()
            .OrderBy()
            .Expand()
            .Count()
            .SkipToken()
            .SetMaxTop({ODataMaximumTop})
            .AddRouteComponents(
                "odata",
                edmBuilder.GetEdmModel(),
                new DefaultODataBatchHandler()); // Include the handler only when $batch is selected.
    });
```

The runner resolves each named Boolean from the same immutable `CapabilitySelection` used for DI and endpoint
mapping, then passes those values through the owning module/component contribution cascade. This preserves the
project-reference direction: a module never references the runner's selection type. Do not re-read
configuration or create a second OData selection snapshot. `{DatabaseName}` comes from the selected shared
persistence structure. `{ODataMaximumTop}` is the confirmed positive integer query limit gathered by the
generator. Substitute both; they are not literal placeholders in generated code. Include only the query
features and batch handler actually selected. If no shared `Data` project owns entity sets, omit its
contribution instead of inventing one.

OData controller mapping is deliberately controller-wide. After the gated registration and application-part
selection are complete, the deployable runner calls `MapControllers()` exactly once. When batching is
selected, it calls `UseODataBatching()` before routing. Do not generate `Map{ServiceName}Service`,
`Map{ComponentName}Component`, or `Map{ModuleName}Module` merely for OData discovery, and never call
`MapControllers()` from a module, component, or service. Those explicit `Map*` cascades exist only for
descendants with explicitly mapped endpoints such as Minimal APIs.

### OData serialization

OData owns its payload format through the selected OData formatter and EDM. Do not force
`Serialization/{ServiceName}JsonSerializerContext.cs`, `[JsonPropertyName]`, or System.Text.Json
source-generation metadata solely for OData. Generate such a context only when the same contract also uses a
selected System.Text.Json transport or the chosen serializer explicitly requires it. Preserve OData names and
compatibility through the EDM and protocol-specific tests.

### OData controller shape

The exact operations come from the confirmed UI contract. This read branch illustrates the boundary without
putting persistence in the controller:

```csharp
namespace {ServiceNamespace}.Api;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OData.Query;
using Microsoft.AspNetCore.OData.Routing.Controllers;
using {ServiceContractNamespace};

public sealed class {EntitySetName}Controller : ODataController
{
    private readonly I{ServiceName} _service;

    public {EntitySetName}Controller(I{ServiceName} service)
    {
        _service = service;
    }

    [EnableQuery(PageSize = {ODataPageSize})]
    public IActionResult Get()
    {
        return Ok(_service.Query{EntitySetName}());
    }
}
```

Merge one entity-set-specific query operation into `I{ServiceName}` and `{ServiceName}Service` for every
selected controller:

```csharp
IQueryable<{EntityTypeName}> Query{EntitySetName}();
```

The service—not the controller—constructs that queryable read surface and applies mandatory tenant,
authorization-scope, soft-delete, or other non-negotiable restrictions before OData options are applied. The
operation name remains unambiguous when one service owns several entity sets. Substitute the confirmed
`{EntityTypeName}`, `{EntitySetName}`, and positive integer `{ODataPageSize}` values gathered by the generator.
For create, update, patch, delete, action, and function operations, define explicit service methods and keep
the controller's role to parsing OData input such as `If-Match` into the service operation's input. The
service owns concurrency enforcement, patch-field policy, transactions, persistence mutation, and business
rules.

### Required OData verification

- Snapshot or structurally verify `$metadata`, including entity sets, navigations, complex types,
  functions/actions, keys, and concurrency annotations.
- Verify every enabled query option, rejected non-enabled option, maximum `$top`, server page size, stable
  ordering/continuation behavior, and representative nested `$expand` paths.
- Verify controller/application-part gating: a disabled module contributes neither controllers nor
  module-private EDM behavior; shared EDM elements remain only when their owning shared data boundary is
  intentionally active.
- Verify independently gated components/services contribute neither controller actions nor their private EDM
  entity sets, functions, actions, or complex types; the same captured selection must drive both exclusions.
- Verify successful and stale `If-Match` mutations, emitted/read ETags, and atomic persistence behavior.
- When batch is selected, verify `$batch` routing, configured quotas, change-set transaction behavior,
  independent-request behavior, and partial failures. Verify batching middleware precedes routing.
- Verify controllers contain protocol translation only and every write/non-query operation delegates to
  `I{ServiceName}`; test the service's behavior separately from the adapter.
- Verify the selected OData formatter without requiring an unrelated System.Text.Json source-generation
  context.

## Required Minimal API verification

- Prove a disabled module is absent from DI and the Host mapping cascade does not traverse it, even when a
  child service flag is true.
- Prove a disabled standalone service is absent from DI and maps no routes.
- Prove an enabled parent registers `I{ServiceName}` before the snapshot-gated `Map{ServiceName}Service` wrapper maps
  the versioned `/api/v1/{ServiceKebabName}` routes; deliberately mismatched composition must fail at startup
  before a route is added.
- Verify validation failures use validation ProblemDetails and unexpected failures use centralized
  ProblemDetails handling.
- Verify OpenAPI contains the versioned operations and declared response schemas.
- Disable reflection fallback in a serialization test and round-trip every request/response type through
  `{ServiceName}JsonSerializerContext`.
- For unbounded collections, replace `GetAll` with the application's canonical paging contract and verify
  page-size limits; never generate an unbounded collection endpoint by default.
- For non-idempotent POST operations, require and test the application's idempotency-key contract.
