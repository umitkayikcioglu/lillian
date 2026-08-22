# Modular Polylith Structure

Each module is a separate `.csproj` with a sibling `.Abstractions` project for cross-module contracts. A single `Host` project wraps the app runner, references the modules, and decides at startup — via feature flags — which modules to register, so the same binary can be deployed as multiple roles. Runner responsibilities and their role-specific boundaries come only from [`solution-structure`](../../solution-structure/SKILL.md#canonical-deployable-runner-identities). Each service inside a module follows the standard service pattern documented in [standard-service.md](standard-service.md).

## Hierarchy

The exact paths and folder contents are defined once in [`solution-structure`](../../solution-structure/SKILL.md#net-solution-folder-structure). This reference defines only what each boundary means:

| Boundary | Responsibility |
|----------|----------------|
| Application abstractions project | Sibling project under `src/` for contracts shared across modules |
| Deployable-runner project | Role-specific process boundary resolved by `solution-structure`; never a home for reusable application/domain behavior |
| Standalone service abstractions project | Optional sibling contract project for a standalone service |
| Standalone service implementation project | Service capability that does not belong to a module |
| Module abstractions project | Public contract for one module |
| Module implementation project | Components and services for one module |
| Component folder | Related services within a module |
| Service folder | One generated service and its capability-specific contents |

The project boundaries are siblings under `src/`; application abstractions are never a folder inside Host:

```text
src/
├── {Organization}.{Product}.Abstractions/           # app-wide contracts, when needed
├── {Organization}.{Product}.Host/                   # composition/app-runner wrapper only
├── {Organization}.{Product}.Services.{ServiceName}.Abstractions/ # when contracts cross the project boundary
├── {Organization}.{Product}.Services.{ServiceName}/ # standalone implementation, when selected
├── {Organization}.{Product}.Modules.{ModuleName}.Abstractions/
└── {Organization}.{Product}.Modules.{ModuleName}/   # business capabilities
```

## Why Polylith, Not Monolith

The Host is **one binary**, but feature flags decide which modules register at startup. The same artifact can deploy in multiple roles:

| Deployment | Active modules | Role |
|---|---|---|
| Recipe service | `RecipeManagement` | API + workers for recipe CRUD/discovery |
| Planning service | `MealPlanning`, `Shopping` | Meal plan and shopping list workers |
| Dev/single-host | All modules | One process for local development |

You get the operational simplicity of a monolith (one Dockerfile, one CI pipeline, one observability stack) with the deployment flexibility of microservices (subset selection per environment).

## Project Boundaries

| Project | Scope | Why separate? |
|---|---|---|
| `{Organization}.{Product}.Abstractions` | App-wide cross-module contracts | Types depended on by multiple modules without forcing a module-to-module dependency |
| Optional shared persistence boundary | Models/Data/Migrations projects selected and owned by [`solution-structure`](../../solution-structure/SKILL.md#canonical-shared-persistence-project-placement) | One canonical shared database-model topology when selected |
| `{Organization}.{Product}.Host` | Process entry point, configuration composition, module registration, hosting/readiness | One thin Host runner; other runner roles and their permitted process-intrinsic artifacts are resolved by `solution-structure` |
| `{Organization}.{Product}.Services.{ServiceName}.Abstractions` | Public contract for a standalone service, when another project consumes it | Consumers reference contracts without pulling in the standalone implementation |
| `{Organization}.{Product}.Services.{ServiceName}` | Standalone service implementation | One sibling project for a capability that does not belong to a module |
| `{Organization}.{Product}.Modules.{ModuleName}.Abstractions` | Module's public contract | Other modules reference contracts without pulling in implementation |
| `{Organization}.{Product}.Modules.{ModuleName}` | Module implementation (components, services) | One module = one project, one feature-flag toggle |

Components and services stay as **folders** inside the module project — they're internal implementation that ships and changes together. Only contracts that cross the **module** boundary get their own `.csproj`. Component-level and service-level `Abstractions/` are folders within the module project, not separate projects, since they only need to be visible inside the module.

Resolve the optional shared persistence boundary exclusively through
[`solution-structure`](../../solution-structure/SKILL.md#canonical-shared-persistence-project-placement).

## Concepts

| Level | Boundary | Visibility | Example |
|---|---|---|---|
| Host | Composition/app-runner wrapper (.csproj) | Picks modules at startup via feature flags; owns no business capability | `{Organization}.{Product}.Host` |
| Module | Separate project (.csproj) | Cross-module contracts in `.Abstractions` sibling project | `RecipeManagement`, `MealPlanning` |
| Component | Folder inside module | Cross-component within module via component `Abstractions/` folder | `Authoring`, `Discovery` |
| Service | Folder inside component | Cross-service within component via service `Abstractions/` folder | `RecipeEditor`, `RecipeSearch` |

### Components Are Always Required

Even single-component modules must have a named component. Avoids ambiguity about where to place services and prevents restructuring when a second component is added.

### Exception Hierarchy

Exceptions cascade through the hierarchy. Module-level base exceptions let you catch broadly at module boundaries:

```csharp
// Module level (in module project)
namespace {Organization}.{Product}.Modules.RecipeManagement.Exceptions;
public class RecipeManagementException : Exception { ... }

// Component level — inherits from module
namespace {Organization}.{Product}.Modules.RecipeManagement.Authoring.Exceptions;
public class AuthoringException : RecipeManagementException { ... }

// Service level — inherits from component
namespace {Organization}.{Product}.Modules.RecipeManagement.Authoring.RecipeEditor.Exceptions;
public class RecipeEditorException : AuthoringException { ... }
```

## Namespace Convention

Namespaces follow the project name plus folder hierarchy:

```
{Organization}.{Product}.Abstractions                                      # separate app-wide contract project
{Organization}.{Product}.Abstractions.Events                               # folder in app-wide Abstractions project
{Organization}.{Product}.Models                                            # optional shared persistence entity project
{Organization}.{Product}.Data                                              # optional shared DbContext/runtime persistence project
{Organization}.{Product}.Migrations                                        # optional migration/design-time project
{Organization}.{Product}.Host                                              # composition-only project
{Organization}.{Product}.Modules.{ModuleName}.Abstractions                  # separate project
{Organization}.{Product}.Modules.{ModuleName}.Abstractions.Events           # folder in Abstractions project
{Organization}.{Product}.Modules.{ModuleName}                               # module project root
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}               # folder in module project
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Abstractions  # folder — cross-component, NOT a separate project
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName} # folder
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Contracts
{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Configuration
{Organization}.{Product}.Services.{ServiceName}                             # separate standalone service project
{Organization}.{Product}.Services.{ServiceName}.Abstractions                # optional sibling contract project
{Organization}.{Product}.Services.{ServiceName}.Contracts
```

Application- and module-level `Abstractions` are separate projects. Component- and service-level `Abstractions/` folders share the module implementation project's assembly and parent namespace. This lets modules consume app-wide or producer-module contracts without referencing another module's implementation assembly.

### Standalone Mode

After applying [`Canonical Gateway edge-adapter ownership`](../../solution-structure/SKILL.md#canonical-gateway-edge-adapter-ownership), an application service that does not belong to a module (for example, an infrastructure service or single-purpose utility) drops the `Modules.{ModuleName}` segment and uses a sibling service project under `src/`:

```
src/{Organization}.{Product}.Services.{ServiceName}/
{Organization}.{Product}.Services.{ServiceName}
{Organization}.{Product}.Services.{ServiceName}.Contracts
```

Generate `{Organization}.{Product}.Services.{ServiceName}.csproj` at that root using the repository's
`Directory.Build.props`, central package management, target framework, analyzers, and capability-selected
references. Do not create a second `{ServiceName}` directory beneath it.

If another project consumes the standalone service's contracts, generate the sibling
`src/{Organization}.{Product}.Services.{ServiceName}.Abstractions/` project and place those contracts there;
consumers reference that abstractions project, not the implementation. Contracts used only inside the
standalone service remain in its `Contracts/` or internal models. A deployable runner may reference and
register the implementation project exactly as Host registers a module; the standalone service project never
references a deployable runner.

## Cross-Module Communication

| Producer | Event | Consumer |
|---|---|---|
| `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}` | `{EventName}` | `{Organization}.{Product}.Modules.{OtherModuleName}.{OtherComponentName}.{OtherServiceName}` |
| `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}` | `{EventName}` | `{Organization}.{Product}.Modules.{ModuleName}.{OtherComponentName}.{OtherServiceName}` (intra-module) |

Cross-module: the consumer's project references the producing module's `.Abstractions` project (e.g., `{Organization}.{Product}.Modules.CookingExperience.Abstractions`) — never the implementation project. Cross-component within a module: reference the producing component's `Abstractions/` folder. Cross-service within a component: reference the producing service's `Abstractions/` folder. Across a standalone-service project boundary: reference its sibling `.Abstractions` project. Never reference internal types across boundaries.

```
Module A (.csproj)                          Module B (.csproj)
┌──────────────────────────┐                ┌──────────────────────────┐
│ Module A's .Abstractions │◄──ProjectRef───┤ consumer implementation  │
│ project (cross-module)   │                │ (consumes A's contracts) │
└──────────────────────────┘                └──────────────────────────┘

┌─────────────────┐                         Component Y (folder, same module)
│ Component X     │                         ┌─────────────────┐
│ /Abstractions/ ◄┼───────folder ref────────┤ consumer code   │
│ (cross-comp)    │                         └─────────────────┘
│                 │
│ Service A       │                         Service B (folder, same component)
│ /Abstractions/◄─┼───────folder ref────────┤ consumer code   │
│ (cross-svc)     │                         └─────────────────┘
└─────────────────┘
```

## Registration Chain

Registration always uses the complete ownership cascade:

- Modular: Host → `Add{ModuleName}Module` → `Add{ComponentName}Component` → `Add{ServiceName}Service`
- Standalone: Host → `Add{ServiceName}Service`

Every existing modular boundary owns exactly one canonical registration method. A module method registers
all of its components, and a component method registers all of its services; neither Host nor a sibling
boundary skips a level to register a descendant. Method naming comes from the generator's
[`Naming`](../SKILL.md#naming) authority.

Endpoint mapping has the same complete names but exists only where explicit mapping is required:

- Modular: Host → `Map{ModuleName}Module` → `Map{ComponentName}Component` → `Map{ServiceName}Service`
- Standalone: Host → `Map{ServiceName}Service`

Generate a `Map*` method at a boundary only when that boundary has an explicitly mapped endpoint descendant,
such as a Minimal API. Adapter-specific mapping behavior comes from [`API Patterns`](api-patterns.md).

Host evaluates its module and standalone-service gates once, before registration, and stores that immutable
selection in DI. Registration and mapping both consume the same snapshot. A disabled parent is therefore not
registered and is never traversed during endpoint mapping. Module, component, and service extensions still
live in their owning implementation projects; Host contains only composition decisions.

Inside an enabled module, module registration installs every descendant service before the mapping cascade
begins. A modular service's optional Boolean is a route-only gate: Host captures it in the same snapshot and
passes it through Module → Component → Service mapping, while registration remains controlled by the parent
module gate. For a standalone service, the Host snapshot uses that service's feature key for both registration
and mapping traversal. No mapper re-reads live configuration, and both modes guarantee that an enabled route
can never precede its service registration.

The full-file example shows both genuinely different placement branches so their relationship is visible.
Emit only the selected branch. `{ServiceName}` remains the service's one canonical PascalCase identity in both
modular and standalone mode; changing the owning root does not create a second service-name token.

### Host Configuration/CapabilitySelection.cs

This strongly typed, immutable-after-binding snapshot is Host composition data, not business logic:

```csharp
namespace {Organization}.{Product}.Host.Configuration;

public sealed class CapabilitySelection
{
    public const string ConfigurationSectionName = "FeatureManagement";

    // Modular mode only: parent module registration/mapping gate.
    public bool {ModuleName} { get; init; }
    // Modular mode: optional independent service-route gate.
    // Standalone mode: the service registration/mapping gate.
    public bool {ServiceName} { get; init; }
}
```

### Host Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Host.Extensions;

using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using {Organization}.{Product}.Host.Configuration;
// Modular mode only.
using {Organization}.{Product}.Modules.{ModuleName}.Extensions;
// Standalone mode only.
using {Organization}.{Product}.Services.{ServiceName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection AddConfiguredCapabilities(
        this IServiceCollection services,
        CapabilitySelection capabilities)
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(capabilities);

        services.AddSingleton(capabilities);

        // Modular mode only.
        if (capabilities.{ModuleName})
        {
            services.Add{ModuleName}Module();
        }

        // Standalone mode only.
        if (capabilities.{ServiceName})
        {
            services.Add{ServiceName}Service();
        }

        return services;
    }

    public static WebApplication MapConfiguredEndpoints(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);

        var capabilities = app.Services.GetRequiredService<CapabilitySelection>();

        // Modular mode only. This complete example gives {ServiceName} an independent route gate.
        if (capabilities.{ModuleName})
        {
            app.Map{ModuleName}Module(capabilities.{ServiceName});
        }

        // Standalone mode only.
        if (capabilities.{ServiceName})
        {
            app.Map{ServiceName}Service(capabilities.{ServiceName});
        }

        return app;
    }
}
```

The configuration shape differs because modular mode has a parent module gate while standalone mode does not.
These are two complete mode inputs, not long and short service-name forms. Emit exactly one.

**Modular mode:**

```json
{
  "FeatureManagement": {
    "{ModuleName}": true,
    "{ServiceName}": true
  }
}
```

**Standalone mode:**

```json
{
  "FeatureManagement": {
    "{ServiceName}": true
  }
}
```

In `Program.cs`, bind the configuration section to the strongly typed composition snapshot before selecting
the service graph. `IConfiguration` remains in the process entry point and is never passed into a registration
extension method:

```csharp
using System;
using Microsoft.Extensions.Configuration;
using {Organization}.{Product}.Host.Configuration;
using {Organization}.{Product}.Host.Extensions;

var capabilities = builder.Configuration
    .GetRequiredSection(CapabilitySelection.ConfigurationSectionName)
    .Get<CapabilitySelection>()
    ?? throw new InvalidOperationException("FeatureManagement configuration is required.");

builder.Services.AddConfiguredCapabilities(capabilities);

var app = builder.Build();

app.MapConfiguredEndpoints();
```

This bootstrap binding is required before the service provider exists because the selection changes the DI
graph itself; runtime service options continue to use `AddOptions<T>().BindConfiguration(...)`. If a
repository selects a richer feature-management provider, evaluate it at the composition boundary and still
capture one strongly typed selection snapshot for both cascades. In standalone mode, the sibling service
project owns `Add{ServiceName}Service` and, when it has explicitly mapped endpoints,
`Map{ServiceName}Service`; Host only invokes them. The standalone project never
references Host.

The restriction applies to application-owned `Add*` and `Map*` API parameters; it does not prohibit a
composition root from satisfying a framework or third-party API that explicitly requires `IConfiguration` or
`IConfigurationSection`. Keep that raw configuration use at the deployable-runner boundary rather than
relaying it through module or service registration/mapping cascades. For example, a Gateway may compose YARP
directly in `Program.cs`:

```csharp
builder.Services
    .AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetRequiredSection("ReverseProxy"));
```

### Module Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.Extensions;

using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Extensions;
using {Organization}.{Product}.Modules.{ModuleName}.{OtherComponentName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ModuleName}Module(
        this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.Add{ComponentName}Component();
        services.Add{OtherComponentName}Component();
        return services;
    }

    public static WebApplication Map{ModuleName}Module(
        this WebApplication app,
        bool serviceNameEnabled)
    {
        ArgumentNullException.ThrowIfNull(app);

        app.Map{ComponentName}Component(serviceNameEnabled);
        app.Map{OtherComponentName}Component();
        return app;
    }
}
```

### Component Extensions/StartupExtensions.cs

```csharp
namespace {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.Extensions;

using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{OtherServiceName}.Extensions;
using {Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Extensions;

public static class StartupExtensions
{
    public static IServiceCollection Add{ComponentName}Component(
        this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.Add{ServiceName}Service();
        services.Add{OtherServiceName}Service();
        return services;
    }

    public static WebApplication Map{ComponentName}Component(
        this WebApplication app,
        bool serviceNameEnabled)
    {
        ArgumentNullException.ThrowIfNull(app);

        app.Map{ServiceName}Service(serviceNameEnabled);
        app.Map{OtherServiceName}Service(true);
        return app;
    }
}
```

Generate each `Map*` method and descendant call only when that boundary contains explicitly mapped endpoint
descendants. Non-HTTP services and OData-controller-only services remain in the mandatory registration
cascade but add no explicit mapping call. The deployable runner maps the composed OData controller surface
once after gated application-part selection. Pass every independently gated
route decision from the immutable Host snapshot through the owning module/component cascade; an ungated child
may receive literal `true`. The service wrapper from
[`standard-service.md`](standard-service.md#extensionsstartupextensionscs) consumes that captured Boolean and
verifies its DI registration before calling the low-level API mapper. No mapping method reads live feature
configuration.

### Service Extensions/StartupExtensions.cs

See [standard-service.md](standard-service.md#extensionsstartupextensionscs) for the service-level registration and mapping pattern.

## Project References

```
{Organization}.{Product}.Host.csproj
├── ProjectReference: {Organization}.{Product}.Abstractions   # only when Host composition directly consumes app-wide contracts
├── ProjectReference: {Organization}.{Product}.Modules.{ModuleName}   # modular mode: compose the module implementation
├── ProjectReference: {Organization}.{Product}.Modules.{ModuleName}.Abstractions   # modular mode only when Host directly consumes its contracts
├── ProjectReference: {Organization}.{Product}.Services.{ServiceName}   # standalone mode: compose the service implementation
└── ProjectReference: {Organization}.{Product}.Services.{ServiceName}.Abstractions   # standalone mode only when Host directly consumes its contracts

{Organization}.{Product}.Modules.{ModuleName}.csproj
├── ProjectReference: {Organization}.{Product}.Abstractions   # only if app-wide types are used
├── ProjectReference: {Organization}.{Product}.Modules.{ModuleName}.Abstractions
└── ProjectReference: {Organization}.{Product}.Modules.{OtherModuleName}.Abstractions   # only when consuming producer-owned contracts from that module

{Organization}.{Product}.Modules.{ModuleName}.Abstractions.csproj
└── ProjectReference: {Organization}.{Product}.Abstractions   # only if app-wide types are used in the contracts

{Organization}.{Product}.Services.{ServiceName}.csproj
├── ProjectReference: {Organization}.{Product}.Abstractions   # only if app-wide types are used
├── ProjectReference: {Organization}.{Product}.Services.{ServiceName}.Abstractions   # when the standalone contract project exists
└── ProjectReference: {Organization}.{Product}.Modules.{ModuleName}.Abstractions   # only when consuming that module's contracts

{Organization}.{Product}.Services.{ServiceName}.Abstractions.csproj
├── ProjectReference: {Organization}.{Product}.Abstractions   # only if app-wide types appear in its contracts
├── ProjectReference: {Organization}.{Product}.Modules.{ModuleName}.Abstractions   # only if module-owned types appear in its contracts
└── ProjectReference: {Organization}.{Product}.Services.{OtherServiceName}.Abstractions   # only for a producer-owned type and an explicitly acyclic dependency direction

{Organization}.{Product}.Services.{OtherServiceName}.csproj
└── ProjectReference: {Organization}.{Product}.Services.{ServiceName}.Abstractions   # when consuming that standalone service's contracts

```

A project declares a direct reference to every abstractions assembly whose types it compiles against, including
types exposed through its own public contracts; do not rely on another project's transitive reference to close
that dependency. A module or standalone service never references another capability's **implementation**.
Before adding a peer abstractions reference, verify that the reverse path does not exist and record the chosen
producer-to-consumer direction; reciprocal or transitive cycles are forbidden. When two standalone services
need mutually shared signature types, move those types to `{Organization}.{Product}.Abstractions` and have
both contract projects reference that broader boundary instead. This explicit acyclic check keeps the
dependency graph DAG-shaped and makes feature-flagged exclusions safe at runtime.

Add any selected shared-persistence references and apply their dependency/runtime restrictions from
[`Canonical shared-persistence project placement`](../../solution-structure/SKILL.md#canonical-shared-persistence-project-placement)
without redefining that graph here.

## Example

Recipe/cooking platform demonstrating multiple modules, components, and services:

```
src/
├── {Organization}.{Product}.Abstractions/
├── {Organization}.{Product}.Host/
│
├── {Organization}.{Product}.Modules.RecipeManagement.Abstractions/
├── {Organization}.{Product}.Modules.RecipeManagement/
│   ├── Authoring/                                  # Write path
│   │   ├── RecipeEditor/                           # CRUD for recipes
│   │   ├── IngredientParser/                       # "2 cups flour" → structured data
│   │   └── MediaUploader/                          # Photo/video handling
│   └── Discovery/                                  # Read path
│       ├── RecipeSearch/                           # Full-text + faceted search
│       ├── Recommender/                            # "You might like" suggestions
│       └── CollectionManager/                      # User-curated collections
│
├── {Organization}.{Product}.Modules.MealPlanning.Abstractions/
├── {Organization}.{Product}.Modules.MealPlanning/
│   ├── Planning/                                   # Weekly meal plans
│   │   ├── PlanBuilder/                            # Drag-drop meal calendar
│   │   └── NutritionCalculator/                    # Aggregate macros
│   └── Shopping/                                   # Grocery lists
│       ├── ListGenerator/                          # Meal plan → shopping list
│       ├── StoreLocator/                           # Find stores, aisle mapping
│       └── PriceTracker/                           # Compare prices
│
├── {Organization}.{Product}.Modules.CookingExperience.Abstractions/
├── {Organization}.{Product}.Modules.CookingExperience/
│   ├── StepByStep/                                 # Guided cooking
│   │   ├── CookingSession/                         # Real-time step tracking
│   │   ├── Timer/                                  # Multi-timer management
│   │   └── Substitution/                           # "Out of X? Use Y"
│   └── Social/                                     # Community features
│       ├── ReviewManager/                          # Ratings + reviews
│       ├── CookingLog/                             # "I made this" history
│       └── ShareManager/                           # Social media sharing
│
├── {Organization}.{Product}.Modules.UserProfile.Abstractions/
└── {Organization}.{Product}.Modules.UserProfile/
    └── Identity/                                   # Single component
        ├── ProfileManager/                         # Preferences, dietary restrictions
        ├── SkillTracker/                           # Beginner → expert progression
        └── NotificationPreferences/                # Email/push settings
```

### Abstractions/ Content

Each `Abstractions` project (module level) and `Abstractions/` folder (component, service levels) contains the same subfolders, organized by communication role:

| Subfolder | Role | Example |
|---|---|---|
| Events/ | What gets published when something happens | `RecipeCreatedEvent` |
| Interfaces/ | Behavioral contracts to implement/consume | `IRecipeEditor` |
| Models/ | Supporting shared types (enums, value objects) | `RecipeStatus`, `Ingredient` |
| Requests/ | What you send to invoke an operation | `CreateRecipeRequest` |
| Responses/ | What you get back | `RecipeResponse` |
