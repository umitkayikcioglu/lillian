---
name: web-frontend-development
description: Token-efficient TypeScript, React, Next.js, and Angular frontend development guidance with manifest-first detection, scope-aware validation, and repository-defined commands.
type: guidance
applies_to:
  - Planner
  - Architect
  - Developer
  - Reviewer
  - Tester
  - Documenter
mandatory: conditional
mandatory_when:
  - Implementing or reviewing TypeScript frontend code
  - Implementing or reviewing React, Next.js, or Angular applications
  - Resolving frontend lint, type-check, test, build, package-manager, or workspace validation
triggers:
  - web frontend
  - frontend development
  - TypeScript
  - React
  - Next.js
  - Nextjs
  - Angular
  - frontend lint
  - frontend test
  - frontend build
references:
  - references/frontend-quality.md
  - references/package-management.md
  - references/typescript.md
  - references/react.md
  - references/nextjs.md
  - references/angular.md
  - references/testing.md
  - references/validation-scenarios.md
summary: TypeScript, React, Next.js, and Angular frontend development with manifest-first stack detection and scope-aware validation.
---

# Web Frontend Development

Use this skill for TypeScript-based frontend work in React, Next.js, and Angular repositories. It integrates with the existing Planner, Architect, Developer, Reviewer, Tester, and Documenter roles; it does not introduce a new workflow role.

## Canonical Ownership

- `references/typescript.md` owns type-system and compiler guidance.
- `references/react.md` owns React components, hooks, state, effects, rendering, and React-specific tests.
- `references/nextjs.md` owns Next.js router, server/client boundaries, data fetching, caching, metadata, route handlers, runtime, deployment, and Next.js-specific tests.
- `references/angular.md` owns Angular DI, standalone/modules, signals/RxJS, templates, routing, forms, change detection, and Angular-specific tests.
- `references/testing.md` owns cross-framework frontend test quality.
- `references/frontend-quality.md` owns validation lifecycle, lint, formatting, type-check, test/build command execution, suppression handling, reporting, and mutation controls.
- `references/package-management.md` owns package managers, workspaces, lockfiles, and command execution.
- `.github/CONTRIBUTING.md` owns cross-stack engineering policy and severity.

Instruction files and prompts are thin loaders. Bootstrap profiles contain concise durable consumer-repository guidance only.

## Deterministic Reference Loading

Maintain a de-duplicated set of loaded references for the task.

1. For any activated frontend task, always load exactly once:
   - `references/frontend-quality.md`
   - `references/package-management.md`
2. Load technology references only after definitive evidence in the relevant package or workspace scope:
   - TypeScript: `references/typescript.md`
   - React: `references/react.md`
   - Next.js: `references/nextjs.md`
   - Angular: `references/angular.md`
3. Load `references/testing.md` only when the task touches tests, creates tests, fixes tests, reviews tests, or requires test validation.
4. If multiple instruction files match a path, still load each canonical reference at most once.
5. Treat path globs as routing hints only. A filename, extension, or directory name must never activate a framework without definitive repository evidence.

## Manifest-First Discovery

Start from manifests and configuration before source files:

1. Inspect root manifests and workspace declarations.
2. Resolve declared workspaces.
3. Inspect only manifests belonging to relevant workspaces or owning packages.
4. Search for relevant manifests only when no workspace declaration exists.
5. Inspect source files only to answer a specific unresolved router, Angular architecture, or ownership question after definitive framework evidence exists.

Exclude `.git`, `.ai`, `.agents`, `.claude`, `plugins`, `node_modules`, `bin`, `obj`, `dist`, `build`, `coverage`, generated output, vendored folders, and caches.

## Definitive Framework Evidence

Activate frameworks only from definitive evidence:

| Framework | Definitive evidence |
|-----------|---------------------|
| TypeScript | `tsconfig*.json` or a declared `typescript` dependency |
| React | Declared `react` dependency or peer dependency |
| Next.js | Declared `next` dependency |
| Angular | `angular.json` or declared `@angular/core` dependency |

Supporting-only signals include source extensions, directory names, `next.config.*`, `app/`, `pages/`, middleware, route handlers, CI commands, framework-like scripts, JSX/TSX alone, and Angular-style filenames alone.

After activation, inspect minimal evidence to classify:

- Next.js App Router: `app/` or `src/app/`.
- Next.js Pages Router: `pages/` or `src/pages/`.
- Mixed Next.js router state: both router trees present.
- Angular standalone architecture: `standalone: true`, `bootstrapApplication`, or standalone route imports.
- Angular module-based architecture: `NgModule`, module declarations, or module imports.
- Mixed Angular architecture: standalone and module-based evidence together.

## Scope and Command Model

Resolve stack, package manager, and commands per scope. Supported scopes include root, node workspace, node package, Nx project, Turborepo task, Angular project, .NET solution, and .NET project.

Every verified command must preserve:

- scope
- working directory
- package manager
- exact command or script
- command category
- evidence source

Never translate commands between npm, pnpm, Yarn, and Bun. Never invent lint, format, type-check, test, or build commands. Do not treat "not configured" as "passed."

### Nx Project Routing

Definitive Nx evidence includes `nx.json`, a declared `nx` dependency, project declarations in `project.json` or workspace configuration, and valid Nx target definitions. For each touched file:

1. Resolve the most specific owning project root or explicit source root from `project.json` or workspace project declarations.
2. Preserve the project name and root, then resolve only requested targets declared for that project.
3. Preserve executor, configuration, target dependencies, working directory, and the exact command evidenced by repository scripts, CI, or supported Nx invocation configuration.
4. Do not assume `lint`, `test`, `build`, or `e2e` exists; do not invent `nx run`, `nx affected`, projects, or target names.
5. Keep results separate per project. If several projects could own the file, report ambiguity.

### Turborepo Package Routing

Definitive Turborepo evidence includes `turbo.json` or another repository-supported Turbo configuration, a declared `turbo` dependency, declared workspace packages, and configured pipeline or task definitions. For each touched file:

1. Resolve the owning workspace package from the nearest package manifest and declared workspace membership.
2. Resolve a task only when both Turbo configuration and the package's scripts support it.
3. Preserve package name, workspace root, package working directory, task, dependencies, configuration, filters, and the exact command evidenced by scripts or CI.
4. Do not invent filters, translate package-manager syntax, assume package participation, or let a root task erase package attribution.
5. Report absent or ambiguous package/task ownership instead of guessing.

### Angular Project Routing

After Angular activation, read `angular.json` and resolve touched files independently:

1. Record each declared project's name, type, root, source root, targets or architect entries, configurations, and explicitly declared default project.
2. Select the most specific matching project root or source root. A default project does not override path ownership.
3. Resolve lint, test, build, serve, and other commands only from that project's declared targets and repository scripts.
4. Preserve separate results for each touched project; include siblings only when a declared dependency or repository gate requires them.
5. Report overlapping roots, unresolved ownership, or conflicting targets as ambiguity.

## Test Context Routing

Test file and directory path matches identify test context only. Determine ownership from repository evidence:

- For .NET, use the nearest owning `.csproj`; treat `.sln` as grouping/supporting evidence.
- For frontend, use the nearest relevant `package.json`, workspace project, Angular project, or Nx project.
- In mixed monorepos, resolve test policy independently per package or project.
- If ownership is ambiguous, report ambiguity and do not guess a framework.

For .NET scopes, `.github/CONTRIBUTING.md` preserves MSTest as the Lillian standard. Existing xUnit or NUnit usage is a standards mismatch and must not be migrated without explicit approval.

For activated frontend scopes, load `references/testing.md`, `references/frontend-quality.md`, `references/package-management.md`, and any definitively activated framework references. Use existing declared test frameworks and verified scripts.
