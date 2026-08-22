# Design Doc: Improve the Web Frontend Development Skill

## Metadata

**Design Doc ID:** DD-202608091902-improve-web-frontend-development
**Date:** 20260809
**Status:** Draft
**Authors:** Codex — Architect
**Reviewers:** Workflow Reviewer, Developer

## Status

Draft — proposed improvement design based on the review of the skill and its references.

## Context and Scope

The `web-frontend-development` skill provides TypeScript, React, Next.js, Angular, package-manager, workspace, and validation guidance. The review identified gaps that can produce incorrect scope selection, incomplete command attribution, or missing frontend quality controls.

This design covers the skill and its reference documents only. It does not change application code, CI configuration, package manifests, or framework architecture.

### Goals

- Make package and project ownership deterministic in ordinary and tool-specific monorepos.
- Prevent false framework activation and support Angular scopes without `angular.json`.
- Make validation results reproducible, attributable, and reportable.
- Add explicit frontend security, accessibility, and performance quality gates.
- Keep canonical ownership clear between the main skill and its references.

### Non-Goals

- Introducing a new frontend framework or package manager.
- Mandating a specific test runner, formatter, linter, or build tool.
- Replacing `.github/CONTRIBUTING.md` as the cross-stack policy source of truth.
- Implementing a validation CLI in this change.

## Prioritized Findings

### Major

- **M1 — Generic workspace ownership is incomplete:** npm, pnpm, Yarn, and Bun workspaces lack a deterministic package/project routing model outside Nx, Turborepo, or Angular-specific handling.
- **M2 — Angular routing has a missing fallback:** `@angular/core` can activate the skill without `angular.json`, but the routing procedure then requires `angular.json` and provides no alternate project/target resolution path.
- **M3 — Frontend security and production-quality gates are under-specified:** React and Angular guidance does not explicitly cover secret exposure, XSS/CSRF/CSP/auth boundaries, dependency risk, or performance budgets.

### Minor

- **m1 — Canonical ownership overlap:** `frontend-quality.md` and `package-management.md` both claim command-execution ownership.
- **m2 — Scenario loading is undefined:** `validation-scenarios.md` is listed as a reference but has no deterministic loading rule.
- **m3 — Package-manager validity is underspecified:** valid `packageManager` values and nested lockfile precedence are not defined precisely.
- **m4 — Vite is only represented by a scenario:** there is no explicit Vite evidence or routing guidance for React packages.
- **m5 — Output contract lacks a concrete example:** required validation-report fields are listed, but a canonical sample result is not provided.

## Overview

The skill should operate as a deterministic pipeline:

1. Discover repository and workspace manifests.
2. Resolve the owning package/project for each touched path.
3. Resolve the effective package manager and exact command evidence.
4. Activate only frameworks supported by effective dependency/configuration evidence.
5. Load the minimum canonical references once.
6. Run or report validation by scope and category.
7. Apply frontend security, accessibility, and performance gates where applicable.
8. Emit a structured result containing evidence, command, scope, and blocker status.

The central architectural change is to make workspace ownership a first-class concern instead of handling only Nx, Turborepo, and Angular-specific routing.

## Detailed Design

### 1. Canonical Reference Ownership

The current ownership statement gives both `frontend-quality.md` and `package-management.md` responsibility for command execution. Split ownership as follows:

| Concern | Canonical owner |
|---|---|
| Repository and package/project ownership | New `references/workspace-routing.md` |
| Package manager, lockfiles, install mutation policy | `references/package-management.md` |
| Exact validation categories, suppression, reporting, formatter mutation | `references/frontend-quality.md` |
| TypeScript rules | `references/typescript.md` |
| Framework-specific behavior | `react.md`, `nextjs.md`, `angular.md` |
| Cross-framework test quality | `testing.md` |
| Scenario matrix | `validation-scenarios.md` |
| Cross-stack policy and severity | `.github/CONTRIBUTING.md` |

The main `SKILL.md` remains the orchestration and reference-loading entry point. It should not duplicate detailed package-manager or framework rules.

### 2. Workspace and Scope Resolution

Add a routing procedure that applies to all workspace types:

1. Identify the repository root and all applicable workspace declarations.
2. Resolve the package/project containing each touched file using the most specific declared root or source root.
3. Preserve one result per owning package/project; do not flatten results into a root-level result.
4. Resolve the package manager using a validated `packageManager` field, then workspace configuration, then one consistent lockfile. Report conflicts.
5. Resolve commands from the owning package's scripts, declared project targets, or exact CI commands. Never infer framework defaults.
6. Include sibling packages only when a declared target dependency or repository gate requires them.
7. Report unresolved ownership as ambiguity and stop command selection for that scope.

For ordinary npm, pnpm, Yarn, and Bun workspaces, define ownership from workspace membership and the nearest package manifest. Keep root scripts separate from package scripts. If a root command intentionally fans out to packages, preserve the exact root command and its evidence rather than inventing package filters.

### 3. Framework Activation and Angular Fallback

Use effective scope evidence rather than only a directly colocated manifest. A dependency declared at the workspace root may activate a framework for a child package only when that package is a declared workspace member and dependency resolution confirms the package can consume it.

Angular routing must support both cases:

- `angular.json` exists: use project roots, source roots, targets, and configurations.
- `angular.json` does not exist: use the owning package/project manifest, Nx/project configuration when present, and repository scripts. If ownership or targets remain unresolved, report ambiguity rather than requiring a nonexistent file.

Add an explicit evidence table for Angular standalone, NgModule, mixed, and custom-build projects. Do not activate Angular from a filename such as `*.service.ts` alone.

### 4. Frontend Quality Gates

Keep the existing validation categories, but add a clear gate model:

| Category | Missing command | Failed command | Completion effect |
|---|---|---|---|
| Lint | Report as not configured | Blocker according to repository policy | Cannot claim validation passed |
| Format check | Report as not configured | Blocker when required by repository policy | Cannot claim validation passed |
| Type-check | Report as not configured | Blocker | Cannot complete implementation |
| Tests | Report by test level | Classify by repository severity | Required levels must pass |
| Build | Report as not configured | Blocker when build is a repository gate | Cannot complete implementation |
| Security/accessibility/performance | Report configured or absent | Apply repository-approved severity | Must be explicitly accepted if absent for the scope |

The report must include scope, working directory, package manager, exact command, category, evidence source, result, and blocker status for every attempted or unavailable category.

### 5. Frontend Security, Accessibility, and Performance

Add a compact cross-framework quality reference or section with repository-aware checks:

- No server secrets, private tokens, or unrestricted environment values in client bundles.
- Authorization and authentication checks remain at the correct server/API boundary.
- User-controlled content is escaped or sanitized according to the framework and existing repository pattern.
- CSRF, CORS, CSP, and cookie settings are reviewed when the application architecture requires them.
- New dependencies follow the approval policy and existing lockfile rules.
- Interactive UI has semantic controls, labels, keyboard behavior, focus handling, and loading/error/empty states.
- Performance checks use existing repository budgets or scripts; if no budget exists, report that capability as not configured rather than inventing one.

These checks supplement, and do not override, `.github/CONTRIBUTING.md`.

### 6. Reference Loading and Scenario Coverage

Make `validation-scenarios.md` an explicit QA reference: load it when validating the skill or changing routing/activation rules, not for every ordinary frontend task. Add scenarios for:

- Generic npm/pnpm/Yarn/Bun workspaces with nested packages.
- Root package scripts versus package-local scripts.
- Workspace-root dependency activation with package ownership evidence.
- Angular with `@angular/core` but no `angular.json`.
- Conflicting `packageManager` and lockfile evidence.
- Ambiguous overlapping package/project roots.
- Vite-backed React packages without introducing a Vite-specific skill.
- Security boundary checks and missing quality capabilities.

### 7. Structured Validation Output

Use a stable report shape:

| Field | Required content |
|---|---|
| Scope | Repository, workspace, package, Nx project, Turbo package/task, Angular project, or .NET scope |
| Working directory | Absolute or repository-relative execution directory |
| Owner | Package/project name and root |
| Package manager | npm, pnpm, Yarn, Bun, or not applicable |
| Framework evidence | TypeScript/React/Next.js/Angular evidence path |
| Category | lint, format, type-check, test level, build, security, accessibility, performance |
| Command | Exact command, or `not configured` |
| Evidence | Manifest, script, target, CI path, or configuration path |
| Result | passed, failed, skipped, ambiguous, or not configured |
| Blocker | yes/no plus reason |

This prevents a missing command from being reported as a successful check and makes multi-package results independently reviewable.

## Cross-Cutting Concerns

### Security

The skill must explicitly preserve client/server boundaries and prevent accidental secret exposure. Dependency additions remain subject to the approval and lockfile policies in `.github/CONTRIBUTING.md`.

### Privacy

Validation guidance must avoid requiring real user data, production tokens, or sensitive fixtures. Test and diagnostic output should redact secrets and personal data.

### Scalability

Manifest-first discovery should avoid scanning `node_modules`, generated output, and unrelated packages. Scope resolution should be per touched path so large workspaces do not require repository-wide source inspection.

### Monitoring

This is a documentation/skill artifact rather than a runtime service. Its quality is monitored through validation scenarios and CI checks for reference consistency, scenario coverage, and report-field completeness.

## Observability Requirements

| SLI | Target | Dashboard | Alert Threshold |
|---|---:|---|---|
| Validation scenario pass rate | 100% | Skill QA results | Critical if any required scenario fails |
| False framework activation rate | 0% | Skill QA results | Critical on any false positive |
| Scope ownership resolution accuracy | 100% of unambiguous cases | Workspace routing results | Warning below 100%; critical for wrong-owner execution |
| Command attribution completeness | 100% of reported categories | Validation report quality | Critical when scope, command, or evidence is missing |
| Duplicate canonical reference loads | 0 | Loader diagnostics | Warning on any duplicate; critical if behavior diverges |

## Testing Strategy

- **Unit:** Validate routing and evidence precedence as table-driven scenarios where test infrastructure exists.
- **Integration:** Run the skill against representative repository fixtures: plain package workspace, Nx, Turborepo, Angular CLI, and mixed .NET/frontend repository.
- **E2E:** Verify a touched file produces the correct owning scope, framework references, exact command, and independent result row.
- **Performance:** Confirm excluded directories are not scanned and unrelated workspace packages are not loaded.
- **Other (security, accessibility, chaos):** Add fixture cases for client-secret exposure, missing auth boundary evidence, accessibility obligations, and unavailable quality capabilities.

Acceptance criteria:

1. A generic workspace resolves package ownership without requiring Nx or Turborepo.
2. Angular without `angular.json` is either routed from valid project evidence or reported as ambiguous.
3. Conflicting package-manager evidence never produces a manager-specific verified command.
4. Every validation result contains the required structured output fields.
5. Missing lint, test, or build commands are reported as not configured, never passed.
6. Security, accessibility, and performance applicability is visible in the final report.

## Alternatives Considered

### Alternative 1: Keep the current skill and add only more examples

Rejected. Examples would not resolve the missing ownership model or canonical command responsibility.

### Alternative 2: Split the skill into separate package-manager and framework skills

Rejected for now. Splitting would increase routing complexity and duplicate the shared validation lifecycle. Keep one orchestration skill with canonical references and add a dedicated workspace-routing reference.

### Alternative 3: Introduce a validation CLI immediately

Deferred. A CLI may be useful later, but the first step is to define deterministic rules and regression scenarios that a CLI could implement safely.

## Metrics

| Metric | Target | How Measured |
|---|---:|---|
| Required validation scenarios passing | 100% | Scenario suite in `validation-scenarios.md` or equivalent fixtures |
| Wrong-package command executions | 0 | Routing fixture results and review logs |
| Missing evidence fields in reports | 0 | Structured output validation |
| Unapproved dependency-install mutations | 0 | Lockfile mutation checks |
| False framework activations | 0 | Negative activation scenarios |

## Rollout Plan

- **Phase 1 (Canonical ownership):** Clarify `SKILL.md`, split command ownership, and add the workspace-routing reference.
- **Phase 2 (Routing):** Implement generic workspace ownership and Angular no-`angular.json` fallback guidance.
- **Phase 3 (Quality):** Add security, accessibility, performance, and structured validation-output rules.
- **Phase 4 (Regression):** Expand validation scenarios, run the scenario suite, and update generated skill indexes if frontmatter changes.
- **Migration:** Existing Nx, Turborepo, Angular, and framework-specific guidance remains valid; only ambiguous routing is replaced by the new precedence rules.
- **Deprecation:** Remove duplicated command-ownership language and obsolete Angular assumptions after Phase 2 is accepted.

## Timeline

| Phase | Target Date | Description |
|---|---|---|
| Design Finalization | TBD | Approve this improvement design |
| Implementation | TBD | Update skill and references |
| Testing | TBD | Execute routing and validation scenarios |
| Rollout | TBD | Merge after review and generated-index verification |

## Open Questions

- Should `references/workspace-routing.md` be a new canonical reference, or should its content live in `package-management.md`?
- Should frontend security checks be a separate reference or remain in `frontend-quality.md`?
- Is a Vite-specific reference needed, or are repository-defined scripts sufficient?
- Which CI workflow should become the authoritative gate for the skill scenario suite?

## Notes for Developer

- Do not change application code as part of the skill update.
- Preserve the repository rule that commands must come from package manifests, project targets, scripts, or CI evidence.
- Use relative links from skill references and update `.github/skills/INDEX.md` only through the repository’s generated-index workflow when frontmatter changes.
- Add negative scenarios for every new activation rule to prevent false positives.
- Keep all framework references version-aware without hard-coding a framework default command.

## Skills to Apply

| Skill | How to Apply |
|---|---|
| `web-frontend-development` | Primary subject; update orchestration, routing, validation, and framework guidance. |
| `documentation-generator` | Use the design-doc structure, metadata, placement, and references conventions. |
| `solution-structure` | Place this report under `/docs/designs/` with a dated slug filename. |
| `observability` | Apply the Architect requirement to define measurable quality indicators and thresholds for the skill QA process. |

## References

- [`web-frontend-development/SKILL.md`](../../.github/skills/web-frontend-development/SKILL.md)
- [`frontend-quality.md`](../../.github/skills/web-frontend-development/references/frontend-quality.md)
- [`package-management.md`](../../.github/skills/web-frontend-development/references/package-management.md)
- [`angular.md`](../../.github/skills/web-frontend-development/references/angular.md)
- [`validation-scenarios.md`](../../.github/skills/web-frontend-development/references/validation-scenarios.md)
- [`CONTRIBUTING.md`](../../.github/CONTRIBUTING.md)
- [`workflow-architect.agent.md`](../../.github/agents/workflow-architect.agent.md)
- [`design-doc.md`](../../.github/skills/documentation-generator/templates/design-doc.md)
