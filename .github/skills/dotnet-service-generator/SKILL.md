---
name: dotnet-service-generator
description: Interactive scaffolder for .NET service modules with observability and DI conventions. Use when creating a new service, scaffolding or adding a service module, or generating service boilerplate.
type: guidance
applies_to:
  - Developer
  - Architect
mandatory: conditional
mandatory_when:
  - Creating a new .NET service
  - Scaffolding service modules
triggers:
  - create a service
  - scaffold service
  - add a new service
  - generate service boilerplate
references:
  - references/standard-service.md
  - references/background-service.md
  - references/api-patterns.md
  - references/dependencies.md
  - references/health-check.md
  - references/modular-polylith.md
summary: Interactive scaffolder for .NET service modules with observability and DI conventions.
---

# .NET Service Generator

Interactive scaffolder for .NET services with full observability support.

> **Folder layout source of truth:** [`solution-structure`](../solution-structure/SKILL.md#net-solution-folder-structure)
> defines both the modular service folder and sibling standalone-service project paths. This skill owns
> service-root file names, generated code, and capability-specific contents; it does not place business
> artifacts beneath any deployable composition/app-runner wrapper or redraw the repository layout.
> Before treating code currently beneath a runner as a service, apply
> [`Canonical Gateway edge-adapter ownership`](../solution-structure/SKILL.md#canonical-gateway-edge-adapter-ownership).
> Only a target classified there as an application service enters this workflow.

## Workflow

1. Gather information interactively
2. Identify dependencies from service purpose
3. Present dependency checklist for confirmation
4. Determine service lifetime
5. Generate files to specified location

## Step 1: Gather Basic Info

Ask these questions (one or two at a time):

1. **Service name** - PascalCase (e.g., `PaymentProcessor`, `UserNotification`)
2. **Organization and product** - Confirm the PascalCase `{Organization}` and `{Product}` values that form
   the namespace root `{Organization}.{Product}`
3. **Purpose** - Brief description (used to identify dependencies)
4. **Structure mode** - Modular (requires PascalCase module and component names) or standalone sibling
   project. "Standalone" never means "inside a deployable runner."
5. **Output location** - After the runner-boundary classification above, confirm the complete application-service root (standalone sibling project: `src/{Organization}.{Product}.Services.{ServiceName}/`; modular polylith: `src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/`).
6. **Interaction boundary and API adapter** - Classify each interaction and select its adapter using
   [`API Patterns — Select the API Adapter`](references/api-patterns.md#select-the-api-adapter). One service may
   expose more than one adapter for distinct confirmed consumers; never generate one merely because the service
   exists.
7. **OData contract** - When OData is selected, gather every input required by
   [`Required OData semantics`](references/api-patterns.md#required-odata-semantics), including any independent
   child gate and the structure-owned `{DatabaseName}` when shared persistence supplies the EDM.
8. **Consumer boundary** - Classify each interface, request, response, and event independently: used only
   by this service's implementation, exposed as this service's HTTP/message wire contract, consumed by
   another service in the same component, consumed by another component in the same module, consumed by
   another module, or shared across modules/app-wide. Default `I{ServiceName}` to service-internal
   `Contracts/`. Internal request/response/model types stay internal; a selected public wire contract or
   cross-service contract uses the exact producer boundary below. Never infer a cross-project contract
   location from the C# `public` modifier alone.

After selecting modular or standalone mode, calculate the service tokens once. Resolve each contract
artifact's namespace separately from its confirmed consumer boundary:

Resolve composition method names through [Naming](#naming). Reject or normalize an input such as
`CatalogComponent` before token substitution so the structural suffix is applied exactly once.

For a selected OData branch, resolve `{ODataMaximumTop}` and `{ODataPageSize}` from the confirmed positive
integer limits and substitute them in registration, controller attributes, and tests. Resolve each
`{EntitySetName}` / `{EntityTypeName}` pair and `{DatabaseName}` through the selected EDM/persistence ownership.
`{EntityTypeName}` is the unqualified semantic CLR type name; its namespace comes from that resolved owner.
Do not leave any of these tokens in generated code.

| Token | Modular value | Standalone value |
|-------|---------------|------------------|
| `{ServiceRoot}` | `src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}` | `src/{Organization}.{Product}.Services.{ServiceName}` |
| `{ServiceNamespace}` | `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}` | `{Organization}.{Product}.Services.{ServiceName}` |
| `{ServiceContractNamespace}` | Default `{ServiceNamespace}.Contracts`; otherwise the confirmed producer-boundary `.Interfaces` namespace | Default `{ServiceNamespace}.Contracts`; otherwise the confirmed producer-boundary `.Interfaces` namespace |
| `{RequestContractNamespace}` | Branch shorthand when every shown request shares one boundary: service-level public wire/cross-service defaults to `{ServiceNamespace}.Abstractions.Requests`; otherwise use the confirmed producer-boundary `.Requests` namespace | Branch shorthand when every shown request shares one boundary: service-owned public wire defaults to `{ServiceNamespace}.Abstractions.Requests`; otherwise use the confirmed producer-boundary `.Requests` namespace |
| `{ResponseContractNamespace}` | Branch shorthand when every shown response shares one boundary: service-level public wire/cross-service defaults to `{ServiceNamespace}.Abstractions.Responses`; otherwise use the confirmed producer-boundary `.Responses` namespace | Branch shorthand when every shown response shares one boundary: service-owned public wire defaults to `{ServiceNamespace}.Abstractions.Responses`; otherwise use the confirmed producer-boundary `.Responses` namespace |
| `{EventContractNamespace}` | Branch shorthand when every shown event shares one boundary: service-level public wire/cross-service defaults to `{ServiceNamespace}.Abstractions.Events`; otherwise use the confirmed producer-boundary `.Events` namespace | Branch shorthand when every shown event shares one boundary: service-owned public wire defaults to `{ServiceNamespace}.Abstractions.Events`; otherwise use the confirmed producer-boundary `.Events` namespace |

Resolve `{ServiceKebabName}` and `{ServiceSnakeName}` once from the complete PascalCase `{ServiceName}` by
splitting its word boundaries, lowercasing each word, and joining them with `-` or `_`, respectively. For
example, `PaymentProcessor` becomes `payment-processor` and `payment_processor`. Substitute the appropriate
resolved token wherever a selected route, metric, or test artifact references it.

The confirmed `{ServiceRoot}` already contains `{ServiceName}`. Resolve
each contract namespace independently from that artifact's consumer-boundary answer and substitute it in the
declaration, serialization context, and every consumer import. The role-wide tokens shown in reference
branches are shorthand only when all selected artifacts of that role share a boundary. If two requests,
responses, or events of the same role land at different boundaries, resolve and substitute an artifact-specific
token named for the concrete CLR type (for example, a request-specific namespace token derived from that
type's complete name) for each one
and import every distinct namespace; never force them through one role-wide token. Do not move only a file
while leaving its old namespace behind.

Resolve each exposed signature as a dependency closure before generating files. A contract may reference only
BCL types, types in its own boundary/project, or types from a broader shared boundary that its owning project
is allowed to reference. For example, an interface moved to module or app-wide abstractions cannot expose a
request that remains inside a service/component implementation folder. Move the dependent DTO to the same or
a dependency-safe broader abstractions boundary, or keep the interface at the narrower boundary. App-wide
abstractions never reference module/service projects; module and standalone-service abstractions never
reference their implementation projects.

## Step 2: Identify Dependencies

Based on service purpose:

| If the service... | Likely needs |
|-------------------|--------------|
| Calls external APIs | `Clients/` with typed HTTP client |
| Makes simple HTTP calls | IHttpClientFactory |
| Caches data | HybridCache or IDistributedCache |
| Reads/writes database | DbContext |
| Uploads/downloads files | ICloudStorageFactory |
| Sends/receives messages | IMessageQueueFactory |
| Needs coordination/locking | IDistributedLock |
| Runs discrete work on a schedule or polling loop | `{ServiceName}Worker.cs` (extends `WorkerBackgroundService`) |
| Holds a long-lived broker subscription | A descriptively named `BackgroundService` subscriber adapter |
| Needs an interaction adapter | Select it from [`API Patterns — Select the API Adapter`](references/api-patterns.md#select-the-api-adapter) |

## Step 3: Confirm Dependencies

Present numbered checklist:

```
Based on your description, I identified:
[x] 1. Clients/ with typed HTTP client (for external API calls)
[x] 2. HybridCache (for caching responses)

Additional options:
[ ] 3. IDistributedCache
[ ] 4. IDistributedLock
[ ] 5. DbContext (direct)
[ ] 6. Repository/UoW pattern (in Internals/)
[ ] 7. ICloudStorageFactory
[ ] 8. IMessageQueueFactory
[ ] 9. {ServiceName}Worker.cs (scheduled/polling background service)
[ ] 10. Broker subscriber adapter (long-lived BackgroundService; automatically includes option 8)
[ ] 11. Versioned Minimal API adapter (cross-deployment synchronous service API)
[ ] 12. OData controller adapter (UI data/query API)

Confirm or adjust (e.g., "add 4, remove 2"):
```

When `DbContext` is selected, also confirm whether the context and persistence model are owned by this one
capability or by the optional shared topology from
[`Canonical shared-persistence project placement`](../solution-structure/SKILL.md#canonical-shared-persistence-project-placement).
The dependency implementation pattern is in [`references/dependencies.md`](references/dependencies.md#dbcontext-direct).

When a broker subscriber is selected, also confirm the producer-owned event contract, the event and subscriber names, the provider/topic configuration keys, and the concrete transient-versus-invalid exception policy before generating code. The canonical artifact and lifecycle pattern is in [`references/dependencies.md`](references/dependencies.md#imessagequeuefactory).

When `Clients/` is selected, confirm the exact PascalCase external-system/client role as `{ExternalApi}` and
the deployment-specific base URL before generating any client artifact. Resolve one `{ExternalApi}` value per
integration; do not reuse one vague client name for multiple external systems.

When a scheduled/polling worker is selected, confirm every dependency that must be ready before work begins
and whether its integration already supplies an `IHealthCheck`. Generate a custom
`{DependencyName}HealthCheck.cs` only for a confirmed dependency that lacks one; never emit a registration for
a health-check type that does not exist. The complete generator-owned patterns cover only HTTP,
`IDistributedCache`, and Entity Framework connectivity. For any other dependency, require an existing concrete
integration-owned health check or a user-confirmed, side-effect-free readiness operation and its required
types before generation. If neither exists, stop and report that the startup dependency gate cannot be
implemented safely; do not invent a probe or silently omit the gate.

## Step 4: Determine Service Lifetime

Suggest based on dependencies:

- **Singleton**: Stateless services, HttpClient wrappers, and hosted adapters
- **Scoped**: Database access or request/delivery-specific state; singleton hosted adapters resolve these services through a new scope per execution or message
- **Transient**: Lightweight, stateless, no shared resources

Set `{ServiceLifetime}` to exactly `Singleton`, `Scoped`, or `Transient` and substitute it in DI
registration. Do not leave the token in generated source.

## Step 5: Generate Files

Generate implementation-owned files directly into the confirmed `{ServiceRoot}/`; the path
already includes `{ServiceName}`. Write any routed contract artifact at its resolved producer boundary instead
of duplicating it under the service root:

### Always Generate

| Path | Purpose |
|------|---------|
| `Configuration/{ServiceName}Settings.cs` | Configuration with validation |
| Resolved `I{ServiceName}.cs` artifact (default `Contracts/I{ServiceName}.cs`) | Service interface; move this one file to the selected producer boundary when it is externally consumed |
| `Extensions/StartupExtensions.cs` | DI registration through canonical `Add{ServiceName}Service` |
| `Constants.cs` | Domain constants + Metrics nested class |
| `{ServiceName}Service.cs` | Core business logic implementation |
| Standalone mode only: `{Organization}.{Product}.Services.{ServiceName}.csproj` | Sibling service project using repository build/package conventions and capability-selected references |

### Create When Needed

Folders are created only when they have content. Do not create empty folders.

Capability references define additions to the same Settings, contract, service, and StartupExtensions files.
Merge those additions once; do not generate parallel copies or let a later capability overwrite an earlier
capability's settings, operations, validation, or registrations.

| Condition | Path |
|-----------|------|
| Contract consumed by another service in the same component | Producer service `Abstractions/{Role}/` folder |
| Contract consumed by another component in the same module | Producer component `Abstractions/{Role}/` folder |
| Contract consumed by another module | Producer module's sibling `{Organization}.{Product}.Modules.{ModuleName}.Abstractions/{Role}/` project |
| Contract shared app-wide or without one producer module | Sibling `{Organization}.{Product}.Abstractions/{Role}/` project |
| Contract crossing a standalone-service project boundary | Sibling `{Organization}.{Product}.Services.{ServiceName}.Abstractions/{Role}/` project |
| Versioned Minimal API exposure | `Api/{ServiceName}Api.cs` + `Api/{OperationName}Endpoint.cs` per endpoint |
| Versioned Minimal API exposure | `Serialization/{ServiceName}JsonSerializerContext.cs` |
| OData UI data/query exposure | `Api/{EntitySetName}Controller.cs` per exposed entity set plus the EDM contribution described in `references/api-patterns.md` |
| OData UI data/query exposure | Serializer artifacts follow [`OData serialization`](references/api-patterns.md#odata-serialization) |
| External HTTP API wrappers | `Clients/` |
| Custom exceptions | `Exceptions/` |
| Internal helper implementations | `Internals/` (interfaces go to `Contracts/`) |
| Object mapping needed | `Mappers/{ServiceName}Mapper.cs` |
| Internal entities/domain objects | `Models/` |
| Grafana dashboard | `Observability/Grafana/` |
| Embedded resources (SQL, templates, etc.) | `Resources/` with subfolders by type |
| Custom validation attributes | `Validators/` |
| Scheduled/polling background service | `{ServiceName}Worker.cs` |
| Long-lived broker subscription | `{EventName}Subscriber.cs` (thin `BackgroundService` adapter) |
| Health monitoring | `{ServiceName}HealthCheck.cs` |
| Startup dependency lacks a concrete readiness check | `{DependencyName}HealthCheck.cs` only when a complete applicable pattern or user-confirmed side-effect-free readiness contract exists; otherwise stop before generation |
| HTTP exposure | The complete `{TestTarget}.http` path resolved from `solution-structure`; never shorten the target to `{ServiceName}` |

`{Role}` is `Events`, `Interfaces`, `Models`, `Requests`, or `Responses`. Contracts with no consumer beyond
the service implementation and no public wire role remain in `Contracts/` or internal `Models/`; do not
create an abstractions artifact merely because a CLR type is declared `public`. The request, response, and
event namespace tokens apply only when that public/cross-boundary artifact is selected.

`{OperationName}` is the exact PascalCase endpoint operation, such as `GetAll`, `GetById`, `Create`, or a
semantic action name. Substitute it in both the endpoint filename and endpoint class; it is not an HTTP-verb
placeholder.

`{EntitySetName}` is the exact PascalCase entity-set identity declared in the composed EDM. Its controller,
EDM entity-set registration, route convention, and tests use the same value. Do not shorten or pluralize it
independently in one layer.

## Code Patterns

Reference snippets use the calculated service and contract namespace tokens from Step 1. Substitute every
token before writing any file; folder suffixes such as `.Configuration` and `.Api` remain unchanged.
Standalone output must contain no `{ModuleName}` or `{ComponentName}` placeholder and no `.Modules.` namespace
segment.

See reference files:

- **Standard service**: [references/standard-service.md](references/standard-service.md)
- **Background service**: [references/background-service.md](references/background-service.md)
- **API patterns**: [references/api-patterns.md](references/api-patterns.md)
- **Optional dependencies**: [references/dependencies.md](references/dependencies.md)
- **Health checks**: [references/health-check.md](references/health-check.md)
- **Modular polylith**: [references/modular-polylith.md](references/modular-polylith.md)

## Observability Guidance

For log level selection and `ActivityKind` usage in generated code, see the [Observability Skill](../observability/SKILL.md#log-levels) — specifically the **Log Levels** and **Activity Kinds** sections.

## Key Conventions

### Architecture Rule: {ServiceName}Service.cs Owns All Business Logic
- `{ServiceName}Service.cs` is the single home for business logic, accessed through `I{ServiceName}`
- Remove the neutral `DoWorkAsync` placeholder once, then merge the union of interface operations required
  by every selected capability (API, scheduled worker, subscriber, health); selecting one capability must not
  erase operations required by another
- `{ServiceName}Worker.cs`, broker subscribers, Minimal API endpoints, and OData controllers are **thin adapters** — they translate between their trigger/protocol and `I{ServiceName}`, never containing business logic themselves
- Minimal API endpoints call `I{ServiceName}` methods and map results to HTTP responses; OData controllers
  expose only the query/command surface deliberately returned by `I{ServiceName}` and delegate mutations to
  it. Neither adapter accesses `DbContext` or performs business decisions directly
- Scheduled workers call `I{ServiceName}` methods and manage scheduling/lifecycle — nothing more
- Broker subscribers own subscription lifecycle and resolve `I{ServiceName}` from a new scope per delivery — nothing more; this supports a scoped service while remaining valid if the chosen lifetime is singleton

### Folder Organization
- Folders are created only when they have content — do not create empty folders
- `Abstractions/` = a contract at the exact producer boundary selected above; a service-local folder must
  not be used for cross-module contracts because it remains in the implementation assembly
- `Contracts/` = internal interfaces (what stays within this service module)
- Service-root `Models/` = internal service-owned entities only; shared-persistence and public-contract
  placement comes from `solution-structure`
- `Internals/` = internal helper implementations (their interfaces go in `Contracts/`)
- Core service files use the `{ServiceName}` prefix: `{ServiceName}Service.cs`, `{ServiceName}Settings.cs`,
  `{ServiceName}Worker.cs`, `{ServiceName}HealthCheck.cs`, `I{ServiceName}.cs`,
  `{ServiceName}Mapper.cs`, and each exception class in its own same-named file. Context-local endpoint,
  validator, and helper files use descriptive class-matching names without inventing a second service-name form.

### Naming
- Public composition methods use one complete form only:
  `Add{ModuleName}Module` / `Map{ModuleName}Module`,
  `Add{ComponentName}Component` / `Map{ComponentName}Component`, and
  `Add{ServiceName}Service` / `Map{ServiceName}Service`. The low-level Minimal API mapper is the one internal
  `Map{ServiceName}Api`. Append each structural suffix exactly once and do not generate suffix-free aliases.
- Generate a `Map*` method only when its boundary has a descendant that needs explicit endpoint mapping.
  Adapter-specific mapping comes from [`API Patterns`](references/api-patterns.md).
- Variables match interface: `IDistributedCache` → `_distributedCache`
- Settings class: `{ServiceName}Settings` (in `Configuration/` folder — keeps the prefix for cross-service disambiguation)
- ConfigurationSectionName: `nameof({ServiceName})`

### Constructor Order
1. `ILogger<T>`
2. `IDistributedTracing`
3. `IMeterFactory`
4. `IOptions<TSettings>`
5. Optional dependencies (alphabetical)

### Lifetime Registration

`Extensions/StartupExtensions.cs` must apply the lifetime selected in Step 4: `AddSingleton`, `AddScoped`,
or `AddTransient`. Hosted adapters are singleton; they may inject the business service directly only for
the singleton branch. Scoped and transient branches resolve it from a fresh async scope per execution or
delivery. Do not emit a fixed lifetime that contradicts the selected answer.

### Meter Creation
Meter creation follows the [observability skill](../observability/SKILL.md#instrumentation-example). Full-file
reference blocks name every required using and prerequisite; blocks explicitly labeled as additions or usage
fragments are merged into the owning file rather than copied as standalone files.

### Metric Constants
Define metric names in `Constants.Metrics` nested class to ensure consistency between code and Grafana dashboards:
```csharp
public static class Constants
{
    public static class Metrics
    {
        public const string ActiveRequests = "app_{ServiceSnakeName}_active_requests";
        public const string OperationTotal = "app_{ServiceSnakeName}_operation_total";
        public const string OperationDuration = "app_{ServiceSnakeName}_operation_duration_seconds";
    }
}
```

## Output Format

After generation, provide:
1. List of generated files
2. Sample `appsettings.json` section
3. Sample `Program.cs` registration
