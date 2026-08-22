---
name: solution-structure
description: Source of truth for the opinionated .NET solution folder structure, including in-repo documentation and test naming, root scaffolding, deployable runners, modular or standalone services, optional shared persistence projects, dashboards, /tools/Kubernetes, and /tests. Use when deciding folder structure, directory layout, repo layout, or where a file belongs.
type: guidance
applies_to:
  - Developer
  - Architect
  - Documenter
  - Tester
  - DBA
  - Reviewer
mandatory: conditional
mandatory_when:
  - Deciding where a file/folder goes inside the .NET solution
  - Placing a doc, dashboard, Kubernetes manifest, embedded SQL, or service scaffold
triggers:
  - folder structure
  - directory layout
  - solution structure
  - repo layout
  - where does this go
  - file placement
  - opinionated folder
references: []
summary: Source of truth for the opinionated .NET solution folder structure, including documentation and test naming, deployable runners, modular or standalone services, optional shared persistence projects, dashboards, Kubernetes, and tests.
---

# Solution Structure

Source of truth for the opinionated **.NET solution** folder structure. When any skill places a file inside this repo, its project, directory, and structural filename rules come from here. The one explicit capability-level exception is the `dotnet-service-generator`: after this skill resolves the complete service root, that skill owns the service implementation artifact filenames generated inside it. That delegation does not create a short naming form.

> Scope: this skill defines **only** the in-repo `.NET Solution` layout. It does **not** cover workspace structure (`%USERPROFILE%\Source\...`), company-wide document taxonomy, email aliases, RBAC / queue / artifact / repository naming — those are separate concerns owned elsewhere.

## Consumers

| Skill | Reads from this skill |
|-------|-----------------------|
| `dotnet-service-generator` | Complete modular and standalone service roots, the folder shape defined here, and the optional shared `Models`, `Data`, and `Migrations` roots and dependency direction; after a service root is resolved, the generator owns capability-specific service implementation artifact filenames inside it |
| `documentation-generator` | Every in-repo documentation directory, filename, scoped placement, and attachment folder shape; that skill owns document purpose, content, lifecycle, metadata, and identifiers |
| `infrastructure` | `/tools/Kubernetes/{base,overlays}` Kustomize layout |
| `observability` | Optional `/Observability/Grafana/dashboard.json` placement at product, runner, module, component, and service scopes |
| `mssql-table-scaffolder` | `/Resources/SQL/` placement when SQL is embedded in a service |
| `mssql-bulk-data-operations` | `/docs/tickets/.../attachments/` or `/docs/runbooks/.../attachments/` placement for operational SQL scripts |
| `pressure-test` | Repository/product Pressure-test result directory and timestamped Markdown/HTML basename |
| `storm-research` | Repository/product Research briefing directory and timestamped HTML filename |

---

## Documentation Placement and Naming Rules

This skill is the sole source of truth for every in-repo documentation directory and filename. The
[`documentation-generator`](../documentation-generator/SKILL.md) skill owns document purpose, content,
lifecycle, metadata, and identifiers; it does not redefine physical placement or names.

### Canonical documentation scope roots

Select the narrowest owning scope allowed by the document catalog. These are the complete physical roots; do
not invent shorter module, component, service, ticket, or project variants.

| Scope | Canonical root | Structural rule |
|---|---|---|
| **Repository / Product** | `/docs/` | Lowercase `docs`; owns repository-wide and product-wide documentation. |
| **Module** | `/src/{Organization}.{Product}.Modules.{ModuleName}/Docs/` | PascalCase `Docs` beneath the complete module project name. |
| **Component** | `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/Docs/` | PascalCase `Docs` beneath the complete module and component hierarchy. |
| **Service** | Modular: `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/Docs/`<br>Standalone: `/src/{Organization}.{Product}.Services.{ServiceName}/Docs/` | One documentation scope and form. The service's established placement selects the owning-project root; both use PascalCase `Docs`. |
| **Ticket** | `/docs/tickets/{TicketId}/` | One folder per external ticket. `{TicketId}` is the complete external tracker identifier, including its tracker prefix; for GitHub issue 42 it is `GITHUB-42`, never `42`. |
| **Project** | `/docs/projects/P{N}/` | One folder per sequential internal project identifier. |

For a catalog row, the full path is its allowed canonical scope root, followed by its relative directory, then
its exact filename. A relative directory of `.` means directly inside the selected scope root. A typed relative
directory such as `runbooks/` is mandatory at every allowed scope: a modular service runbook is
`/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/Docs/runbooks/{slug}.md`,
never a shortened `Docs/runbook.md`. Existing repositories may update an established contextual basename in
place, but every new document uses the full canonical form below.

### Canonical document catalog

Each documentation-generator template appears exactly once. The catalog owns physical scope, relative
directory, filename, and attachment applicability. Document purpose, lifecycle, metadata, and identifiers
remain owned by [`documentation-generator`](../documentation-generator/SKILL.md).

| Document type (template) | Allowed scopes | Relative directory | Exact filename | Attachments | Structural special case |
|---|---|---|---|---|---|
| Architecture Decision Record (`architecture-decision-record.md`) | Repository / Product; Module; Component; Service | `adrs/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | Keep the full timestamp and slug in both document and attachment basenames. |
| Request for Comments (`request-for-comments.md`) | Repository / Product; Module; Component; Service | `rfcs/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | Keep the full timestamp and slug in both document and attachment basenames. |
| Design Doc (`design-doc.md`) | Repository / Product | `designs/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | Repository/product placement only. |
| Runbook (`runbook.md`) | Repository / Product; Module; Component; Service | `runbooks/` | `{slug}.md` | Yes | No date or type prefix in the physical filename. |
| Standard Operating Procedure (`standard-operating-procedure.md`) | Repository / Product | `sops/` | `{slug}.md` | Yes | No date or identifier prefix in the physical filename. |
| Post Incident Review (`post-incident-review.md`) | Repository / Product | `pirs/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | Repository/product placement only. |
| Takeover and Handover (`takeover-handover.md`) | Ticket | `.` | `Handoff.md` | Yes | Required fixed noun-form output name; the same template covers incoming Takeover and outgoing Handover. |
| Data Dictionary (`data-dictionary.md`) | Repository / Product | `.` | `data-dictionary.md` | No | Fixed root singleton; no shared root attachment directory. |
| Business Glossary (`business-glossary.md`) | Repository / Product | `.` | `business-glossary.md` | No | Fixed root singleton; no shared root attachment directory. |
| Tech Stack Overview (`tech-stack-overview.md`) | Repository / Product | `.` | `tech-stack-overview.md` | No | Fixed root singleton; no shared root attachment directory. |
| Architecture Overview (`architecture-overview.md`) | Repository / Product; Module; Component; Service | `architectures/` | `{slug}.md` | Yes | Multiple files are allowed per scope; the slug states the covered system or area. |
| Business Case (`business-case.md`) | Project | `.` | `BusinessCase.md` | Yes | Required fixed project-local name. |
| Business Case Financial Model (`business-case-financial-model.md`) | Project | `.` | `BusinessCaseFinancialModel.md` | Yes | Fixed optional project-local name. |
| Project Status Update (`project-status-update.md`) | Project | `StatusUpdates/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | Preserve PascalCase `StatusUpdates`. |
| Retrospective (`retrospective.md`) | Project | `.` | `Retrospective.md` | Yes | Fixed project-local name. |
| Test Plan (`test-plan.md`) | Repository / Product; Module; Component; Service | `test-plans/` | `{yyyyMMddHHmm}-{slug}.md` | Yes | One physical form only. Project and Release are semantic scopes, not additional physical roots: both remain under the Repository / Product root and record `Project P{N}` or `Release v[X.Y]` in metadata. |
| Test Cases (`test-cases.md`) | Repository / Product; Module; Component; Service | `test-cases/` | `{slug}.md` | Yes | No date or type prefix in the physical filename. |
| Brag Document (`brag-document.md`) | Outside repository | — | — | N/A | Personal artifact; this solution layout does not assign its storage or filename. |
| Performance Improvement Plan (`performance-improvement-plan.md`) | Outside repository | — | — | N/A | HR artifact; this solution layout does not assign its storage or filename. |
| Role Brief (`role-brief.md`) | Outside repository | — | — | N/A | HR-adjacent intake artifact; this solution layout does not assign its storage or filename. |

### Non-template documentation artifacts

These structural items do not correspond to a documentation-generator template.

| Artifact | Allowed scopes | Relative directory | Exact filename | Attachments | Structural special case |
|---|---|---|---|---|---|
| Documentation index | Repository / Product | `.` | `README.md` | No | Master index for the repository/product documentation tree. |
| Service overview | Service | `.` | `README.md` | No | Service-local overview; not a second form of another document type. |
| Machine-readable specifications | Repository / Product | `specs/` | `{slug}.yaml` or `{slug}.json` | No | The files are the artifacts. |
| Shared diagrams | Repository / Product | `diagrams/` | `{slug}.puml`, `{slug}.excalidraw`, or `{slug}.mermaid`; a generated render keeps the same basename, for example `{slug}.svg` | No | Source and generated render are sibling artifacts in `diagrams/`; neither uses an attachment directory. |
| Analysis notebooks | Repository / Product | `notebooks/` | `{slug}.ipynb` | No | The files are the artifacts. |
| Pressure-test result | Repository / Product | `pressure-tests/` | `{yyyyMMddHHmm}-{slug}.md`; an optional visual uses the same basename with `.html` | No | Generated advisory output; leave uncommitted unless the user explicitly requests repository inclusion. |
| Research briefing | Repository / Product | `research/` | `{yyyyMMddHHmm}-{slug}.html` | No | Generated, citation-verified output; leave uncommitted unless the user explicitly requests repository inclusion. |

### Structural attachment convention

Non-Markdown supporting material—diagram sources and renders, screenshots, spreadsheets, raw data, benchmark
output, and recordings—lives in the document's typed directory under
`attachments/{DocumentBasename}/`. `DocumentBasename` is the exact physical filename without `.md`, preserving
timestamp, slug, spelling, and case.

The directory is literally `attachments`. Do not substitute `artifacts`, which collides with build and CI
artifact vocabulary, or `assets`, which commonly means rendered-site static files. Attachments are evidence
owned by one document.

```text
{TypedDirectory}/
├── {DocumentFilename}
└── attachments/
    └── {DocumentBasename}/
        ├── diagram.puml
        ├── diagram.svg
        ├── benchmark.json
        └── screenshot.png
```

Rules:

- The attachment subfolder matches the document basename exactly, including timestamp, slug, spelling, and case.
- Every `Yes` row uses its own attachment subfolder. Ticket and project containers are not shared attachment bags.
- Ticket and project scope roots are folders even when they contain only their required fixed document.
- Link from the document to supporting material with a relative path.
- Create the attachment subfolder only when material exists; do not create empty directories.
- Keep editable sources and generated renders together when both are committed.
- The non-template `specs`, `diagrams`, and `notebooks` rows do not use attachments because their files are the artifacts.
- Root singletons and README files do not use a generic root attachment directory. Embed small support inline or create an appropriate typed document instead.
- Commit only shareable support. Personal scratch, raw recordings, and sensitive data belong outside the repository.

Full examples:

| Document | Attachment directory |
|---|---|
| `/docs/adrs/202604240930-queue-choice.md` | `/docs/adrs/attachments/202604240930-queue-choice/` |
| `/docs/runbooks/deploy-worker.md` | `/docs/runbooks/attachments/deploy-worker/` |
| `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/Docs/runbooks/replay-messages.md` | `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/Docs/runbooks/attachments/replay-messages/` |
| `/src/{Organization}.{Product}.Services.{ServiceName}/Docs/test-plans/202604241200-resilience.md` | `/src/{Organization}.{Product}.Services.{ServiceName}/Docs/test-plans/attachments/202604241200-resilience/` |
| `/docs/tickets/GITHUB-42/Handoff.md` | `/docs/tickets/GITHUB-42/attachments/Handoff/` |
| `/docs/projects/P3/BusinessCase.md` | `/docs/projects/P3/attachments/BusinessCase/` |
| `/docs/projects/P3/StatusUpdates/202604241100-week18.md` | `/docs/projects/P3/StatusUpdates/attachments/202604241100-week18/` |
| `/docs/test-plans/202604241200-p3-release-validation.md` with project scope in metadata | `/docs/test-plans/attachments/202604241200-p3-release-validation/` |

---

## .NET Solution Folder Structure

> **Deployable-runner boundary:** `{Organization}.{Product}.Host` is a composition/app-runner wrapper only,
> and an orchestration AppHost owns orchestration declarations only. A Gateway is also a deployable runner, but
> its process responsibility includes intrinsic edge adapters as defined below. No runner owns reusable
> application contracts, domain/business logic, or data access.

The application Host's process-level HTTP utility behavior comes from
[`Deployable-process HTTP endpoints`](../../instructions/csharp.instructions.md#deployable-process-http-endpoints).
Those endpoints remain runner composition behavior and do not make Host an application or domain layer.

### Canonical deployable-runner identities

Runner roles are genuinely different process responsibilities, but every runner keeps the complete
organization/product identity. Do not abbreviate these project names.

| Runner role | Canonical project root | Canonical project file | Responsibility |
|---|---|---|---|
| Application host | `/src/{Organization}.{Product}.Host/` | `{Organization}.{Product}.Host.csproj` | Application process entry point and composition. |
| Edge gateway | `/src/{Organization}.{Product}.Gateway/` | `{Organization}.{Product}.Gateway.csproj` | Edge/proxy process entry point, route/cluster composition, and process-intrinsic ingress or egress adapters. |
| Orchestration AppHost | `/src/{Organization}.{Product}.AppHost/` | `{Organization}.{Product}.AppHost.csproj` | Local/distributed application orchestration declarations. |

`{DeployableProcessName}` is the exact complete project stem selected from this table, such as
`{Organization}.{Product}.Host`. Reuse it for the runner directory, project file, assembly, and process
identity. Kubernetes deployment identities are resolved once in the
[canonical Kubernetes directory structure](#canonical-kubernetes-directory-structure).

`{GatewayEdgeAdapterName}` is the exact PascalCase capability name of a selected process-intrinsic Gateway
adapter, such as `Webhook`. It names a contextual folder and its implementation prefix beneath the complete
Gateway project root; it is not a second or shortened Gateway identity.

### Canonical shared-persistence project placement

When a solution intentionally uses one application-wide Entity Framework database model and `DbContext`, use
this optional sibling-project topology as one matched persistence boundary. These projects are not required in
solutions whose capabilities own separate persistence models.

`{DatabaseName}` is the exact PascalCase semantic name of that shared database model. Resolve it once from the
actual schema/context identity and reuse it in every shown directory, `DbContext`, and EDM-contribution name;
it is not an alias for `{Product}` and must not be left unresolved.

| Project | Owns | Must not own |
|---|---|---|
| `{Organization}.{Product}.Models` | Generated DB-first entity partials, hand-authored entity partial extensions, persistence-policy marker interfaces, and database-tied schema/seed/status constants or enums | API DTOs, application contracts, domain services or rules, `DbContext`, clients, or migrations |
| `{Organization}.{Product}.Data` | The shared `DbContext`, EF configurations and conventions, interceptors and query filters, provider/options registration, shared-context EDM contributions when OData is selected, and shared persistence integrations | Business services, API contracts, migration classes, or design-time startup |
| `{Organization}.{Product}.Migrations` | EF migration classes and model snapshot, `IDesignTimeDbContextFactory`, and migration-only configuration | Runtime composition, business logic, or reusable data access |

`Models/Abstractions` is a contextual persistence folder, not an alternative application-wide abstractions
project. It contains only marker contracts whose semantics are inseparable from persistence policy, such as
audit stamping, timestamps, soft deletion, or temporal history. Cross-project application contracts still use
the sibling `{Organization}.{Product}.Abstractions` project, and domain behavior still uses its owning
`Domain`, module, component, or service boundary.

The dependency direction is acyclic:

```text
{Organization}.{Product}.Models
    ↑
{Organization}.{Product}.Data
    ↑
{Organization}.{Product}.Migrations
```

Any module, service, runner, or test adds a direct reference to each persistence project whose types its own
source compiles against; it does not rely on transitive references. A module that injects the shared context
references `Data`; one that also names an entity references `Models` directly. A deployable runner may
reference `Data` only to compose runtime registration. Production runners and capability projects never
reference `Migrations`; tests reference it only when they explicitly apply or verify migrations.

```
/.vscode                                    // Visual Studio Code settings
  - settings.json                           // Workspace settings
  - launch.json                             // Debugging configuration
  - tasks.json                              // Task configuration
  - extensions.json                         // Recommended extensions
/.git                                       // Git configuration
  - config                                  // Git configuration file
/.github                                    // GitHub configuration
  - CODEOWNERS                              // Code owners for the repository
  - PULL_REQUEST_TEMPLATE.md                // Pull request template
  /ISSUE_TEMPLATE                           // Issue templates
    - bug_report.yml                        // Bug report template
    - feature_request.yml                   // Feature request template
    - custom_template.yml                   // Custom template
  /workflows                                // GitHub Actions workflows
    - ci.yml                                // CI/CD pipeline for continuous integration
    - checks.yml                            // CI/CD pipeline for running checks and tests

/docs                                       // Repository/product-level documentation
  - README.md                               // Master index — pointers to sections below
  - business-glossary.md                    // SINGLETON — no /attachments/ (promote to its own typed folder if support material is needed)
  - data-dictionary.md                      // SINGLETON — no /attachments/
  - tech-stack-overview.md                  // SINGLETON — no /attachments/

  /adrs                                     // Typed document directory
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}                // Per-doc supporting files (diagrams, screenshots, data, recordings)
  /rfcs                                     // Typed document directory
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /designs                                  // Typed document directory
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /specs                                    // Machine-readable contract definitions — OpenAPI, GraphQL, JSON Schema, etc. (no /attachments/ — these ARE the artifacts)
    - {slug}.yaml
    - {slug}.json
  /diagrams                                 // Shared system/architecture diagrams referenced by multiple docs (no /attachments/ — these ARE the artifacts)
    - {slug}.puml                           // PlantUML source
    - {slug}.excalidraw                     // Excalidraw source
    - {slug}.mermaid                        // Mermaid source
    - {slug}.svg                            // Optional generated render; same basename as its editable source
  /notebooks                                // Jupyter notebooks for analysis or runnable examples (no /attachments/ — these ARE the artifacts)
    - {slug}.ipynb
  /pressure-tests                           // Generated pressure-test archives; uncommitted unless explicitly requested
    - {yyyyMMddHHmm}-{slug}.md
    - {yyyyMMddHHmm}-{slug}.html            // Optional visual form with the same basename
  /research                                 // Generated citation-verified research briefings; uncommitted unless explicitly requested
    - {yyyyMMddHHmm}-{slug}.html

  /architectures                            // Typed document directory
    - {slug}.md                             // Multiple files allowed
    /attachments
      /{slug}
  /runbooks                                 // Typed document directory
    - {slug}.md
    /attachments
      /{slug}
  /sops                                     // Typed document directory
    - {slug}.md
    /attachments
      /{slug}
  /pirs                                     // Typed document directory
    - {yyyyMMddHHmm}-{slug}.md
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /test-plans                               // Typed document directory
    - {yyyyMMddHHmm}-{slug}.md              // One canonical physical form
    /attachments
      /{yyyyMMddHHmm}-{slug}
  /test-cases                               // Typed document directory
    - {slug}.md
    /attachments
      /{slug}

  /tickets                                  // Ticket scope roots
    /{TicketId}                             // Complete external tracker ID; for example GITHUB-42
      - Handoff.md                          // Required fixed document
      /attachments
        /Handoff                            // Subfolder name matches doc basename — holds scripts, screenshots, investigation notes, raw data, recordings

  /projects                                 // Project scope roots
    /P{N}                                   // Always a folder; one per project
      - BusinessCase.md                     // Required fixed document
      - BusinessCaseFinancialModel.md       // Optional fixed document
      - Retrospective.md                    // Fixed document
      /StatusUpdates                        // Typed project subdirectory
        - {yyyyMMddHHmm}-{slug}.md
        /attachments
          /{yyyyMMddHHmm}-{slug}            // Per-update supporting files
      /attachments
        /BusinessCase                       // Each subfolder matches a doc basename in this folder
        /BusinessCaseFinancialModel
        /Retrospective
```

### Canonical Kubernetes directory structure

This is the complete structural authority for `/tools/Kubernetes/`. Each actual deployment owns one complete
base and only the environment overlays that the product supports. A solution with one deployment still uses
the same complete form; it does not introduce a shorter layout.

```
/tools
  /Kubernetes
    /base
      /{DeploymentName}                     // One actual complete deployment identity
        - kustomization.yaml                // Required base composition for this deployment
        - deployment.yaml                   // Required complete Deployment baseline
        - service.yaml                      // Optional Service manifest
        - configmap.yaml                    // Optional non-secret configuration manifest
    /overlays
      /{KubernetesEnvironmentKebabName}      // One supported environment; no empty environment directories
        /{DeploymentName}                   // One actual complete deployment identity
          - kustomization.yaml              // Required; composes base/{DeploymentName} and selected patches
          - deployment.yaml                 // Required environment/role/resource patch
          - service.yaml                    // Optional Service patch
          - configmap.yaml                  // Optional non-secret configuration patch
```

`{KubernetesEnvironmentName}` is one supported semantic environment value: `Integration`, `Testing`,
`Staging`, or `Production`. `{KubernetesEnvironmentKebabName}` is its one lowercase path/label rendering:
`integration`, `testing`, `staging`, or `production`. Create only the values the product supports.

`{DeploymentName}` is the complete deployment identity. It equals `{DeployableProcessName}` when that process
has one runtime role. When one binary has several roles, append the explicit role to the complete process
identity, such as `{Organization}.{Product}.Host.Api` and `{Organization}.{Product}.Host.Worker`; never replace
it with positional aliases such as `default` or `alternative`.

Every base and overlay pair uses the same complete `{DeploymentName}`, so multiple runners such as Host and
Gateway—and multiple explicit roles of one binary—coexist without sharing or overwriting a manifest identity.
There is deliberately no root `kustomization.yaml`, environment-level `kustomization.yaml`, `repo/` image
layer, or mandatory empty environment. The infrastructure guidance owns manifest content and deployment
behavior; it does not add another directory layer.

### Canonical tests, root, and source directory structure

This continues the .NET solution tree after the separately detailed Kubernetes subtree. It is not part of the
Kubernetes layout.

```
/tests
  - {TestTarget}.http                                   // HTTP requests for one complete canonical target
  /{TestTarget}.{TestType}.Tests                        // One canonical form; TestTarget is the complete namespace under test
    - {TestTarget}.{TestType}.Tests.csproj              // TestType is Unit, Integration, or E2E
    - ...
  /{Organization}.{Product}.Tests.Common                         // Shared test utilities, fixtures, mocks
    - {Organization}.{Product}.Tests.Common.csproj
  /...
.dockerignore                               // Docker ignore file
.editorconfig                               // Editor configuration file
.gitattributes                              // Git attributes file
.gitignore                                  // Git ignore file
LICENSE                                     // License file
README.md                                   // Readme file explains the project
CHANGELOG.md                                // Changelog file for the project
azure-pipelines.yml                         // Azure DevOps pipeline configuration
Directory.Build.props                       // Common properties for all projects in the solution
Directory.Build.targets                     // Common build targets for all projects in the solution
Directory.Packages.props                    // Central package-version declarations
global.json                                 // Pinned .NET SDK selection
{Organization}.{Product}.slnx              // Visual Studio solution file
/src
  /{Organization}.{Product}.Abstractions             // Separate app-wide contract project (when needed)
    - {Organization}.{Product}.Abstractions.csproj
    /Events
    /Interfaces
    /Models                                           // Enums, value objects, shared DTOs
    /Requests
    /Responses

  /{Organization}.{Product}.Extensions                // Optional reusable implementation project
    - {Organization}.{Product}.Extensions.csproj
    /Contracts                                        // Internal contracts for helpers owned by this project
    /Exceptions                                       // Technical exceptions owned by this project
    /Internals                                        // Reusable technical helper implementations
  /{Organization}.{Product}.Domain                    // Optional domain project; never nested in Host
    - {Organization}.{Product}.Domain.csproj
    /Exceptions                                       // App-wide domain exceptions
    /Models                                           // App-wide domain types and rules

  /{Organization}.{Product}.Models                    // Optional shared-persistence model project
    - {Organization}.{Product}.Models.csproj
    /Abstractions                                     // Persistence-policy markers only; not app contracts
    /{DatabaseName}                                   // Generated DB-first entity partials; overwrite-safe
    /{DatabaseName}Extend                             // Hand-authored entity partial extensions; survives re-scaffold
    /{DatabaseName}Constants                          // Database-tied schemas, seeds, statuses, and enums

  /{Organization}.{Product}.Data                      // Optional shared runtime persistence project
    - {Organization}.{Product}.Data.csproj
    - {DatabaseName}DbContext.cs                      // Generated partial DbContext
    - _{DatabaseName}DbContext.cs                     // Hand-authored partial hooks; survives re-scaffold
    - IDbContextConfigurer.cs                         // Optional runtime options-extension seam
    - ODataExtensions.cs                              // Shared-context EDM contributions when OData is selected
    - SoftDeleteSaveChangesInterceptor.cs             // Example persistence-policy interceptor, when selected
    - StartupExtensions.cs                            // Runtime persistence registration
    /Configurations                                   // IEntityTypeConfiguration implementations

  /{Organization}.{Product}.Migrations                // Optional shared EF design-time project
    - {Organization}.{Product}.Migrations.csproj
    - DbContextFactory.cs                             // IDesignTimeDbContextFactory; never runner-owned
    - appsettings.Migration.json                      // Migration-only configuration
    /Migrations                                       // Generated migrations and model snapshot, when present

  /Observability                                      // Optional app-wide operational assets, outside Host
    /Grafana
      - dashboard.json                                // Platform overview dashboard

  /{Organization}.{Product}.Host
    - Program.cs                                      // Process entry point; invokes composition only
    - ProgramExtensions.cs                            // Host/app-runner composition
    - StartupBackgroundService.cs                     // Optional readiness orchestration; no domain work
    - StartupHealthCheck.cs                           // Optional host readiness check
    - AppConfigurationExtensions.cs                   // Host configuration composition
    - appsettings.json                                // Configuration settings for the application
    - appsettings.Development.json                    // Configuration settings for the development environment
    - appsettings.Integration.json                    // Configuration settings for the integration environment
    - appsettings.Testing.json                        // Configuration settings for the testing environment
    - appsettings.Staging.json                        // Configuration settings for the staging environment
    - appsettings.Production.json                     // Configuration settings for the production environment
    - Dockerfile                                      // Deployable-process container definition
    - {Organization}.{Product}.Host.csproj            // Composition-root project
    - Buildinfo.txt                                   // Build information shown at startup

    /Properties
      - launchSettings.json                             // Local process launch settings
    /Configuration
      - CapabilitySelection.cs                         // Immutable registration/mapping gate snapshot
      - CapabilityControllerFeatureProvider.cs         // Optional process-specific OData controller gate
    /Api                                               // Thin process-level HTTP endpoints
      - PingEndpoint.cs                                // Anonymous application reachability contract
      - MeEndpoint.cs                                  // Authenticated current-user projection
    /Extensions
      - StartupExtensions.cs                           // Registers modules/services selected for this process
    /Components                                       // Optional process-specific Blazor/UI shell; thin presentation only
      - App.razor
      - Routes.razor
      - _Imports.razor
      /Layout
        - MainLayout.razor
        - NavMenu.razor
      /Pages                                           // Process shell/composition pages, not reusable feature behavior
        - ...
    /wwwroot                                           // Optional static assets owned by this deployable process
      - ...

  /{Organization}.{Product}.Gateway
    - Program.cs                                       // Gateway process entry point
    - ProgramExtensions.cs                             // Gateway composition
    - appsettings.json                                 // Gateway process configuration
    - appsettings.Development.json                     // Development overrides
    - Dockerfile                                       // Deployable-process container definition
    - {Organization}.{Product}.Gateway.csproj          // Gateway runner project
    /Configuration
      - CapabilitySelection.cs                         // Immutable edge-capability gate snapshot
    /{GatewayEdgeAdapterName}                          // Optional process-intrinsic edge adapter, such as Webhook
      /Api                                             // Thin edge endpoints and filters
      /Configuration                                   // Adapter-specific process settings
      /Contracts                                       // Internal contracts used only by this adapter
      /Extensions                                      // Adapter registration and mapping
      /Serialization                                   // Adapter-owned wire serialization metadata
      - Constants.cs
      - {GatewayEdgeAdapterName}Service.cs              // Edge translation/forwarding; no domain behavior

  /{Organization}.{Product}.Services.{ServiceName}.Abstractions // Optional standalone-service contract project when another project consumes its contracts
    - {Organization}.{Product}.Services.{ServiceName}.Abstractions.csproj
    /Events
    /Interfaces
    /Models
    /Requests
    /Responses

  /{Organization}.{Product}.Services.{ServiceName}    // Optional standalone implementation; sibling of deployable runners
    - {Organization}.{Product}.Services.{ServiceName}.csproj
    - ...                                              // Apply the exact canonical service-root folder shape shown below; generator owns only capability-specific filenames

  /{Organization}.{Product}.Modules.{ModuleName}.Abstractions    // Separate csproj — module's public contract (cross-module)
    - {Organization}.{Product}.Modules.{ModuleName}.Abstractions.csproj
    /Events
    /Interfaces
    /Models                                          // Enums, value objects, shared DTOs
    /Requests
    /Responses

  /{Organization}.{Product}.Modules.{ModuleName}                 // Module project — owns components and services as folders
    - {Organization}.{Product}.Modules.{ModuleName}.csproj       // References its .Abstractions sibling; references other modules' .Abstractions when consuming their contracts
    - Constants.cs                                   // Module-wide constants
    /Contracts                                       // Module-wide internal interfaces for shared helpers
    /Docs                                            // Optional contextual root; apply the catalog's typed relative directories
    /Exceptions                                      // Module-level base exceptions
    /Extensions
      - StartupExtensions.cs                         // Registers all components in this module
      - ODataExtensions.cs                           // Optional module EDM aggregation/contributions
    /Internals                                       // Module-wide shared helper implementations
    /Observability                                   // Optional module-scoped operational assets
      /Grafana                                       // Module-level domain health dashboard
        - dashboard.json

    /{ComponentName}                                    // Folder inside module project — always required (even single-component modules)
      /Abstractions                                  // Component's public contract (cross-component within module — folder, NOT separate csproj)
        /Events
        /Interfaces
        /Models
        /Requests
        /Responses
      /Contracts                                     // Component-wide internal interfaces for shared helpers
      /Docs                                          // Optional contextual root; apply the catalog's typed relative directories
      /Exceptions                                    // Component-level base exceptions
      /Extensions
        - StartupExtensions.cs                       // Registers all services in this component
        - ODataExtensions.cs                         // Optional component EDM aggregation/contributions
      /Internals                                     // Component-wide shared helper implementations
      /Observability                                 // Optional component-scoped operational assets
        /Grafana                                     // Component-level aggregated dashboard
          - dashboard.json
      - Constants.cs                                 // Component-wide constants

      /{ServiceName}                                    // Folder — full service structure
        /Abstractions                                // Public contract (cross-service within component — folder)
          /Events                                    // Domain events
          /Interfaces                                // Public interfaces (when externally consumed)
          /Models                                    // Enums, value objects, shared DTOs
          /Requests                                  // Request DTOs
          /Responses                                 // Response DTOs
        /Api                                         // HTTP adapters (optional): selected Minimal API endpoints or OData controllers
        /Clients                                     // External HTTP API wrappers
        /Configuration                               // Settings and config binding
        /Contracts                                   // Internal interfaces (DI/testing)
        /Docs                                        // Optional contextual root; apply the catalog's typed relative directories
          - README.md                                // Service overview singleton
        /Exceptions                                  // Service-specific exceptions
        /Extensions                                  // DI registration, model extensions
          - ODataExtensions.cs                       // Optional service-owned EDM contributions
        /Internals                                   // Internal helper implementations
        /Mappers                                     // Object mapping between types
        /Models                                      // Internal entities/domain objects
        /Observability                               // Optional service-scoped dashboards and diagnostics
          /Grafana                                   // Per-service dashboard
            - dashboard.json
        /Resources                                   // Embedded resource files — optional (SQL, templates, etc.)
          /SQL
            - {SqlScriptName}.sql                    // Descriptive PascalCase operation name
            - ResourceLoader.cs                      // Lazy loader for embedded resources
            - Constants.cs                           // Resource file name constants
        /Serialization                               // Service-owned transport/API serializer metadata
        /Validators                                  // Custom validation attributes
        - ...                                        // Service-root files are owned by dotnet-service-generator

      /{OtherServiceName}
        /...

    /{OtherComponentName}
      /...

  /{Organization}.{Product}.Modules.{OtherModuleName}.Abstractions
    /...
  /{Organization}.{Product}.Modules.{OtherModuleName}
    /...
```

### Canonical Grafana dashboard placement

Every generated Grafana dashboard uses the fixed filename `dashboard.json` at the narrowest scope it monitors:

| Monitored scope | Canonical path |
|---|---|
| Product / platform | `/src/Observability/Grafana/dashboard.json` |
| Deployable runner | `/src/{DeployableProcessName}/Observability/Grafana/dashboard.json` |
| Module | `/src/{Organization}.{Product}.Modules.{ModuleName}/Observability/Grafana/dashboard.json` |
| Component | `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/Observability/Grafana/dashboard.json` |
| Modular service | `/src/{Organization}.{Product}.Modules.{ModuleName}/{ComponentName}/{ServiceName}/Observability/Grafana/dashboard.json` |
| Standalone service | `/src/{Organization}.{Product}.Services.{ServiceName}/Observability/Grafana/dashboard.json` |

These are optional structural placements of one full dashboard form, not long and short filename conventions.
The observability guidance exclusively owns whether a dashboard is generated and all dashboard content,
identity, and nonduplication rules.

### Canonical embedded SQL structure

When a modular or standalone service embeds SQL, use the service-root subtree shown above:

```text
/Resources/SQL
  - {SqlScriptName}.sql
  - ResourceLoader.cs
  - Constants.cs
```

`{SqlScriptName}` is a descriptive PascalCase operation name. The .NET service guidance owns how the loader,
constants, and embedded-resource project configuration are implemented.

### Canonical test project and HTTP file naming

In the `/tests` pattern, `{TestTarget}` is never a shortened area token. Both `{TestTarget}.http` and
`{TestTarget}.{TestType}.Tests` use the complete canonical namespace of the subject under test; for a modular
service that means
`{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}`. `{TestType}` is `Unit`,
`Integration`, or `E2E`. One full modular example is
`/tests/{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}.Integration.Tests/`.

#### Test-target applicability

One naming formula does not mean every target/type combination is valid. Generate only these complete HTTP
targets when that boundary actually exposes HTTP behavior:

| HTTP scope | Complete `{TestTarget}` |
|---|---|
| Application host surface | `{Organization}.{Product}.Host` |
| Gateway surface | `{Organization}.{Product}.Gateway` |
| Module surface | `{Organization}.{Product}.Modules.{ModuleName}` |
| Component surface | `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}` |
| Modular service surface | `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}` |
| Standalone service surface | `{Organization}.{Product}.Services.{ServiceName}` |

Test projects use the same complete target identity and only the applicable test types:

| Subject under test | Complete `{TestTarget}` | Allowed `{TestType}` |
|---|---|---|
| Domain project | `{Organization}.{Product}.Domain` | `Unit`, `Integration` |
| Shared persistence models | `{Organization}.{Product}.Models` | `Unit` |
| Shared runtime persistence | `{Organization}.{Product}.Data` | `Unit`, `Integration` |
| Shared EF migrations | `{Organization}.{Product}.Migrations` | `Integration` |
| Module project | `{Organization}.{Product}.Modules.{ModuleName}` | `Unit`, `Integration` |
| Component boundary | `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}` | `Unit`, `Integration` |
| Modular service boundary | `{Organization}.{Product}.Modules.{ModuleName}.{ComponentName}.{ServiceName}` | `Unit`, `Integration` |
| Standalone service project | `{Organization}.{Product}.Services.{ServiceName}` | `Unit`, `Integration` |
| Deployable runner (`Host`, `Gateway`, or `AppHost`) | Its exact canonical runner project name from the table above | `Unit`, `Integration`, `E2E` |

`{Organization}.{Product}.Tests.Common` remains the one explicit non-target exception: it owns shared test
utilities and is not itself a production subject under test.

The service-root folder shape shown under the modular `{ServiceName}` node applies unchanged beneath both the
modular and standalone roots. This skill owns the project, containing path, folders, and the cross-skill
structural filename conventions explicitly shown in the tree. After that root is resolved, the
`dotnet-service-generator` owns all other service implementation artifact filenames and decides which
capability-specific files exist. That single delegation is not permission to invent shortened filenames,
redefine a shown structural filename, or omit a folder required by a selected capability.

The Host is a composition/app-runner wrapper, and AppHost is an orchestration wrapper; neither is an
application layer. A Gateway additionally owns edge adapters intrinsic to that process. Every runner owns its
entry point, configuration and dependency composition, deployable-process assets, and role-specific process
wiring. No runner owns reusable application contracts, domain or business logic, data access, or embedded
business SQL. Those belong in sibling app-wide abstractions/domain projects, module projects, or sibling
standalone service projects. Modules and services never reference a deployable runner.

The former Host-local `Contracts/`, `Exceptions/`, and `Internals/` buckets are deliberately retired rather
than moved as app-wide catch-alls. Resolve each artifact by responsibility:

- cross-project contracts belong in the sibling `{Organization}.{Product}.Abstractions` project;
- domain rules, domain models, and domain exceptions belong in the sibling `{Organization}.{Product}.Domain`
  project when that project is present;
- reusable technical helpers, together with contracts and technical exceptions owned only by those helpers,
  belong in the sibling `{Organization}.{Product}.Extensions` project when that project is present; and
- capability-specific internal contracts, exceptions, and helpers remain with their owning module, component,
  or service; and
- persistence entities and persistence-policy markers belong in `{Organization}.{Product}.Models`, runtime EF
  infrastructure belongs in `{Organization}.{Product}.Data`, and EF design-time artifacts belong in
  `{Organization}.{Product}.Migrations` when the optional shared-persistence topology is selected.

A deployable runner never owns `IDesignTimeDbContextFactory`, migration-only configuration, or migration
classes. Applying migrations from a running application process is not part of the runner boundary; use the
dedicated migrations project from an explicit development or deployment workflow.

A runner may own process-specific UI shell/composition files and static assets. A Gateway may also own the
process-intrinsic edge adapters described below. Reusable feature UI and all application/domain behavior remain
with the owning sibling capability.

### Canonical Gateway edge-adapter ownership

A Gateway runner owns YARP route/cluster composition, process-level proxy mapping, and an ingress or egress
adapter that exists only as part of that Gateway process. For example, a Gateway-owned `Webhook` adapter may
own its authentication and validation, bounded body handling, process-local settings and contracts, thin API
endpoints, serialization metadata, broker forwarding client, resilience, and telemetry under
`/src/{Organization}.{Product}.Gateway/{GatewayEdgeAdapterName}/`. Those are edge translation responsibilities, not a standalone service merely because their
implementation spans several files. The adapter must not make application/domain decisions or access business
data. Extract it to a sibling project only when another process/project consumes it, it gains an independent
deployment or lifecycle, or it becomes reusable application behavior. Likewise, an AppHost may own
orchestration declarations, but it does not become the home of the services it orchestrates.

A standalone service keeps contracts used only by its implementation inside that implementation project.
When another project consumes its public contracts, place them in the sibling
`{Organization}.{Product}.Services.{ServiceName}.Abstractions` project so the consumer does not reference the
service implementation. A deployable runner references the implementation project only to compose it; this
never makes the runner the owner of those contracts or their behavior.
