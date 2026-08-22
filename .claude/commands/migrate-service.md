---
description: Migrate an existing .NET service to current architecture standards
---

# Service Migrator

## Variables

Inspect the target repository first and infer values that are unambiguous. Ask the user only for a required
value that cannot be resolved safely. `{ReferenceRepositories}` is optional and defaults to an empty list.

- **Service name:** `{ServiceName}`
- **Current service path:** `{ServicePath}` — actual path relative to the repository root
- **Repository name:** `{RepositoryName}` — repository being changed
- **Organization:** `{Organization}`
- **Product:** `{Product}`
- **Structure mode:** `{StructureMode}` — `Modular` or `Standalone`
- **Module name:** `{ModuleName}` — required only for modular mode
- **Component name:** `{ComponentName}` — required only for modular mode
- **Reference repositories:** `{ReferenceRepositories}` — optional list of actual repository paths

These values identify the requested service and supplementary evidence; they are not a second path or
namespace specification. Do not concatenate them into target names. Resolve every target project, path,
filename, class name, and namespace through the authorities below.

## Authorities

Before starting, load and follow:

- `.github/skills/solution-structure/SKILL.md` — containing projects, paths, folder layout, and every structural
  filename explicitly shown in its tree
- `.github/skills/dotnet-service-generator/SKILL.md` — all remaining service implementation filenames, class
  names, namespaces, contract boundaries, and capability contents after the structural root is resolved
- `.github/skills/observability/SKILL.md` — logging, tracing, metrics, dashboards, and operational identity
- The dotnet-service-generator references selected by that skill for the service's actual capabilities
- Every applicable target-repository instruction and broad engineering principle

If an existing implementation or example disagrees with an authority, report the drift. Do not copy the
drift into the migration plan.

## Reference Repositories

If `{ReferenceRepositories}` is non-empty, use those repositories only as supplementary implementation
evidence. They do not override the target repository's applicable authorities. If they drift from an
authority, evaluate and report the drift instead of copying it.

## Scope

Migrate only `{ServiceName}` at `{ServicePath}`. Do not restructure other services or shared infrastructure.
Outside that service, change only references invalidated by the approved migration and required composition
or project-reference closure.

## Phase 1: Analyze Current Structure

Scan `{ServicePath}` and produce a report:

1. **Inventory** — list every file and folder and classify its current responsibility.
2. **Identity confirmation** — confirm the repository, organization, product, service, structure mode, and any
   required module/component values against the repository. Ask before proceeding if they are ambiguous.
3. **Capability inventory** — classify each interaction as in-process, cross-deployment machine communication,
   or UI query/data access; identify its current adapter/protocol (including Minimal API, messaging, or OData),
   plus scheduled or polling work, broker subscriptions, health checks, configuration, clients, contracts,
   models, persistence, observability, and other selected capabilities. Inventory the behaviors required by
   the selected generator reference; do not infer an adapter conversion from the target folder structure.
4. **Contract-boundary analysis** — classify each contract independently by producer and consumer boundary.
   Never duplicate a consumed contract or move it merely because another artifact moved.
5. **Canonical resolution** — first apply
   [`Canonical Gateway edge-adapter ownership`](../skills/solution-structure/SKILL.md#canonical-gateway-edge-adapter-ownership)
   to classify the target responsibility and containing project. Only a target classified there as an
   application service enters this migration workflow. Resolve its service root, folders, and explicitly shown
   structural filenames there; then use dotnet-service-generator to resolve every remaining service
   implementation filename, class name, namespace, and capability-specific artifact. Record the actual
   resolved values in the report.
6. **Gap analysis** — list missing projects, folders, files, or registration layers required by the resolved
   structure. Only propose folders that will contain an artifact.
7. **Behavior split analysis** — identify business logic currently held by process runners, API adapters,
   workers, or subscribers and show how the generator's boundaries preserve that behavior while making each
   adapter thin. Preserve the selected API adapter and its protocol semantics unless a separately approved
   behavioral change explicitly replaces them.
8. **Observability analysis** — map every existing log, trace, metric, dashboard, and health signal; identify
   required additions without silently replacing or dropping an existing signal.
9. **Reference comparison** — when supplementary repositories were supplied, record useful evidence and every
   relevant drift from the target authorities.

## Phase 2: Present Migration Plan

Present a table covering every intended change:

1. **File moves** — actual source path to actual resolved destination path.
2. **File/class renames** — old name to the exact name resolved by the owning authority above.
3. **Namespace changes** — old namespace to the independently resolved namespace for each artifact.
4. **Contract moves** — producer boundary, consumer boundary, destination project, and dependency-closure
   updates.
5. **New scaffolding** — only resolved projects and non-empty folders required by solution-structure.
6. **Registration changes** — every affected application, module, component, and service composition layer.
7. **Hosted-adapter split** — trigger type, business behavior delegated to the service, and lifecycle behavior
   retained by the thin adapter.
8. **API-adapter plan** — selected adapter/protocol, generator-resolved artifacts, business behavior delegated
   to the service, and every protocol behavior required by the selected adapter reference.
9. **Observability changes** — preserved signals, required additions, operational identity, and dashboard impact.
10. **Dependent updates** — tests and consumers whose references will become invalid.

Every row must use an actual resolved name or path, not a placeholder formula.

**Wait for user approval before proceeding.**

## Phase 3: Execute Migration

After approval:

1. Create only the resolved projects and non-empty folders approved in the plan.
2. Move files to their approved destinations.
3. Apply the exact generator-owned file and class names from the plan.
4. Apply each artifact's independently resolved namespace and update imports throughout the affected scope.
5. Move public contracts to their resolved producer boundaries and update project references without creating
   implementation-project dependencies from consumers.
6. Split business behavior from thin APIs, scheduled/polling adapters, and broker subscribers exactly as
   approved, preserving the selected API adapter, protocol behavior, and lifecycle semantics. Do not convert
   OData to Minimal API, or Minimal API to OData, as an incidental part of structural migration.
7. Update every affected composition and registration layer.
8. Apply the generator-owned configuration, metrics, serialization, and capability patterns selected during
   analysis, plus the selected observability patterns.
9. Update affected configuration values only when the migration changes their owning type or section.
10. After every move or rename, search for the recorded old path, namespace, class name, and configuration
    reference. Update all valid dependents; zero obsolete references may remain in the affected scope.

## Phase 3b: Update Dependents

1. **Tests** — locate test projects using solution-structure, then update references, imports, construction,
   mocks, fixtures, and configuration invalidated by the migration.
2. **Other consumers** — search all repository projects for recorded old identities. Update only references
   invalidated by this migration; do not restructure dependent services or change their behavior.
3. **Ambiguous consumers** — stop and request user review rather than guessing a new boundary.

## Phase 4: Verify

1. Compare every resulting project, path, folder, and explicitly shown structural filename with
   solution-structure.
2. Compare every other service implementation file, class, namespace, contract boundary, and selected
   capability artifact with dotnet-service-generator.
3. Compare every logging, tracing, metrics, dashboard, health, and operational-identity change with
   observability guidance and the approved plan.
4. Search for the actual pre-migration identities recorded in Phase 1; no obsolete matches may remain in the
   affected scope.
5. Confirm namespaces equal the independently resolved values from the approved plan; do not derive them
   mechanically from folders during verification.
6. Confirm no empty migration-created folders or orphaned imports remain.
7. Confirm the complete resolved registration chain and project-reference direction.
8. Confirm every API entrypoint and execute the selected adapter reference's required verification contract.
9. Build the affected solution/projects and run the relevant tests. Report exact commands and evidence.
10. Report any verification that could not run; never infer success from an unexecuted check.

## Constraints

- **Preserve all business logic** — migrate architecture only; never change behavior without separate approval.
- **Do not restructure other services** — outside the target service, change only references invalidated by
  this migration.
- **Ask before splitting** — the approved plan must explicitly authorize any hosted-adapter or API split.
- **Preserve the API contract** — adapter selection and protocol semantics are behavior, not structural details;
  changing them requires separate explicit approval.
- **Authorities win** — examples and existing repositories are evidence, never naming or placement authority.
- **No shortened migration path** — always perform analysis, approval, execution, dependent updates, and
  verification; do not substitute a reduced workflow based on the command name or existing layout.
