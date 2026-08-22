# Web Frontend Development Validation Scenarios

Use these scenarios as the minimum validation matrix for `web-frontend-development`.

| Scenario | Given | When | Then | Expected Result |
|----------|-------|------|------|-----------------|
| TypeScript-only package | A package has `tsconfig.json` and no React, Next.js, or Angular evidence | Discovery runs | TypeScript activates | TypeScript, frontend-quality, and package-management references load |
| React with Vite | A package declares `react` and Vite scripts | Discovery runs | React activates | React guidance loads and Vite commands are preserved exactly |
| Next.js App Router | A package declares `next` and has `app/` | Discovery runs | Next.js activates and App Router is detected | Next.js App Router guidance applies |
| Next.js Pages Router | A package declares `next` and has `pages/` | Discovery runs | Next.js activates and Pages Router is detected | Pages Router guidance applies |
| Mixed Next.js routers | A package declares `next` and has both `app/` and `pages/` | Discovery runs | Mixed router state is detected | Router boundaries are preserved |
| Ordinary Next component outside router dirs | A package declares `next` and edits a component outside `app/` and `pages/` | Loading runs | Next.js activates from dependency | Next.js guidance loads without relying on path |
| Generic app directory | A package has `app/` but no declared `next` | Discovery runs | App directory is supporting-only | Next.js does not activate |
| Generic workspace ownership | A pnpm, npm, Yarn, or Bun workspace has nested packages without Nx or Turborepo | A file changes inside one package | Workspace membership and the most specific package root resolve ownership | Only the owning package's commands are eligible |
| Root versus package scripts | A workspace has both root fan-out scripts and package-local scripts | Validation resolves a touched package | Script scope is preserved | No package filter or root command is invented |
| Workspace-root dependency evidence | A workspace root declares React and a child package is a declared member that can consume it | Discovery runs | React activates for that owning package | Root dependency activation requires membership and resolution evidence |
| Nested standalone package manager | A nested package has its own valid `packageManager` and lockfile | Command resolution runs | The nested declaration owns that package scope | Parent manager evidence does not override it |
| Valid package manager conflict | A scope has a valid `packageManager` field and a conflicting lockfile | Command resolution runs | The declared manager wins and the conflict is reported | Evidence is retained; no silent selection occurs |
| Generic overlapping roots | Two generic package/project roots match a touched file with equal specificity | Ownership resolves | Ownership is ambiguous | No command or framework is guessed |
| Angular without angular.json | A package declares effective `@angular/core` but no `angular.json` | Angular routing runs | Package/project configuration and scripts are inspected | Valid targets are preserved or ambiguity is reported |
| Angular standalone | An Angular scope has standalone bootstrap evidence | Discovery runs | Angular activates and standalone architecture is detected | Standalone guidance applies |
| Angular NgModule-based | An Angular scope has `NgModule` evidence | Discovery runs | Angular activates and module-based architecture is detected | Module guidance applies |
| Mixed Angular architecture | An Angular scope has standalone and NgModule evidence | Discovery runs | Mixed architecture is detected | Existing boundaries are preserved |
| Generic service file | A `*.service.ts` file exists without `angular.json` or `@angular/core` | Discovery runs | Filename is supporting-only | Angular does not activate |
| Angular multi-project isolation | `angular.json` declares multiple applications and libraries with separate roots and targets | A file changes inside one project | The most specific project root owns the file | Only that project's verified commands apply unless a declared dependency or repository gate requires siblings |
| Angular default project differs | The workspace default project differs from the touched file's owning project | Ownership resolves | The touched path selects its project | The default project does not override path ownership |
| Angular overlapping roots | Multiple Angular project roots or source roots could own a touched file | Ownership resolves | Ownership is ambiguous | No project command is guessed |
| Angular library without build | An Angular library declares test and lint targets but no build target | Validation resolves commands | Only declared targets are selected | Build is reported as not configured for that library |
| Multiple touched Angular projects | Files change in several Angular projects | Validation resolves commands | Each file maps to its owning project | Separate validation rows preserve each project's targets and results |
| React and Angular monorepo | Separate workspace packages declare React and Angular | Discovery runs | Scopes are separated | React and Angular guidance apply only to owning packages |
| .NET and frontend monorepo | Repo has `.csproj` and frontend package scopes | Discovery runs | .NET and frontend scopes are separate | Validation commands are not flattened |
| Nx workspace | Repo has Nx workspace config and package manifests | Discovery runs | Nx projects are scopes | Commands preserve project and working directory |
| Nx project.json ownership | A touched file is under a project root declared by `project.json` | Nx ownership resolves | The nearest project owns the file | Only that project's declared targets can produce verified commands |
| Nx target missing | One owning Nx project lacks the requested target | Command resolution runs | The target is not configured for that project | No target or `nx run` command is invented |
| Nx ambiguous ownership | Overlapping Nx project or source roots could own a touched file | Nx ownership resolves | Ownership is ambiguous | No project or target is selected |
| Turborepo workspace | Repo has Turborepo config and packages | Discovery runs | Turborepo tasks are command evidence | Commands preserve exact task invocation |
| Turborepo package ownership | A touched file belongs to a declared workspace package participating in a Turbo task | Turbo ownership resolves | The nearest workspace package owns the file | Package name, roots, task, dependencies, and exact command remain attributed |
| Turbo task absent | Turbo config declares a task but one touched package lacks the supporting script | Command resolution runs | The package does not participate in that task | No package task or filter is invented |
| Turbo CI filter | CI declares an exact filtered Turbo command for a workspace package | Command resolution runs | The filter is verified from CI | The exact command, package manager, package scope, and evidence path are preserved |
| npm scope | A scope has npm evidence | Command resolution runs | npm is selected | npm scripts are preserved |
| pnpm scope | A scope has pnpm evidence | Command resolution runs | pnpm is selected | pnpm scripts are preserved |
| Yarn scope | A scope has Yarn evidence | Command resolution runs | Yarn is selected | Yarn scripts are preserved |
| Bun scope | A scope has Bun evidence | Command resolution runs | Bun is selected | Bun scripts are preserved |
| Conflicting package managers | A scope has multiple lockfiles without valid declaration | Command resolution runs | Manager is ambiguous | No manager-specific verified command is emitted |
| Lint command present | A package declares a lint script | Validation resolves commands | Lint command is verified | Command, working directory, and evidence are reported |
| Repository lint configuration authoritative | Repository scripts and lint configuration select an existing lint tool and rules | Validation resolves lint | The configured tool and rules are retained | No preferred replacement or unapproved rule strengthening occurs |
| Lint config without script | A package has ESLint config but no lint script or CI command | Validation resolves commands | Lint capability is missing command | No command is invented |
| No lint tooling | A package has no lint scripts, config, dependency, or CI command | Validation resolves commands | Lint tooling is missing | Missing capability is reported |
| CI-only lint | CI has an exact lint command and working directory | Validation resolves commands | CI command is verified | Exact command is reported |
| Existing baseline warning | Lint output includes warnings outside changed files | Validation reports results | Warnings are baseline | They are reported but not cleaned automatically |
| New warning | Lint output includes a warning in changed code | Validation reports results | Warning is new | Severity is Major |
| Zero-warning CI | CI enforces zero warnings | A new warning appears | Severity is evaluated | Severity is Blocker |
| Lint error | Lint output includes an error | Validation reports results | Error is classified | Severity is Blocker |
| TypeScript compiler error | Type-check command reports an error | Validation reports results | Error is classified | Severity is Blocker |
| Justified narrow suppression | A suppression is scoped and justified | Review runs | Suppression is evaluated | Suppression may be accepted |
| Broad suppression | A file-wide suppression hides type or lint defects | Review runs | Suppression is evaluated | Severity is Blocker |
| Stale `@ts-expect-error` | Compiler reports an unused expectation | Review runs | Suppression is stale | Severity is Blocker |
| Non-mutating format check | A format-check script exists | Validation runs | Check does not mutate files | Result is reported |
| Repository formatter configuration authoritative | Repository scripts and formatter configuration select an existing formatter | Validation resolves formatting | The configured formatter and options are retained | No alternative formatter or stronger rules are introduced |
| Generated and vendor exclusions | Tool configuration excludes generated or vendored paths that appear in the diff | Validation selects files | Existing exclusions are honored | Excluded files are not linted or formatted merely because they changed |
| Conflicting exclusion configuration | Scripts, CI, and tool configuration disagree about excluded paths | Validation selects files | Exclusion evidence is ambiguous | The conflict is reported without silently selecting one source |
| Formatter changes unrelated files | A mutating formatter changes files outside approved scope | Diff inspection runs | Unrelated churn is detected | Work stops for isolation or revert |
| Missing test command | No verified test command exists for a scope | Validation resolves commands | Test command is missing | Missing command is reported, not passed |
| Missing build command | No verified build command exists for a scope | Validation resolves commands | Build command is missing | Missing command is reported, not passed |
| Dependency install changes lockfile | Installing dependencies changes a lockfile | Validation or setup runs | Lockfile mutation is detected | Approval is required |
| Ordinary React TypeScript source | Editing a normal `.tsx` file in a React package | Reference loading runs | Frontend quality is always loaded | Quality policy applies even without config path match |
| Overlapping loaders | A Next.js TypeScript component matches several instruction globs | Reference loading runs | References are de-duplicated | Each canonical reference loads once |
| Test task | A task creates or reviews tests | Reference loading runs | Testing reference is selected | `testing.md` loads once |
| Non-test task | A task edits non-test frontend source only | Reference loading runs | Testing details are not needed | `testing.md` is not loaded |
| .NET test routing | A `.cs` test is inside a .NET test project | Test loader resolves ownership | .NET scope is selected | MSTest guidance applies |
| React test routing | A `.tsx` test is inside a React package | Test loader resolves ownership | Frontend React scope is selected | Frontend and React test guidance apply, not MSTest |
| Angular test routing | An Angular `.spec.ts` is inside an Angular project | Test loader resolves ownership | Angular scope is selected | Frontend and Angular test guidance apply, not MSTest |
| Identical test directories | Two packages each have `tests/` directories | Test loader resolves ownership | Each path maps to its own scope | Root framework is not applied universally |
| Ambiguous test ownership | A test file has no owning manifest or project evidence | Test loader resolves ownership | Ownership is ambiguous | No test framework is guessed |
| Test and frontend overlap | A frontend test matches tests and frontend instruction globs | Reference loading runs | References are de-duplicated | Testing, quality, package, and framework references load once |
| Developer command attribution | A validation category is attempted, unavailable, or not configured | Developer reports validation | All attribution fields are populated | Scope, working directory, tool, exact command, category, evidence, result, and blocker are retained |
| Structured validation result | A validation category is attempted or unavailable | Developer reports validation | The canonical result shape is used | Owner, package manager, framework evidence, command, evidence, result, and blocker are present |
| Missing quality capability | A scope has no security, accessibility, or performance command or budget | Validation resolves commands | The capability is reported separately | It is not reported as passed |
| Client secret boundary | A frontend change references server secrets or unrestricted environment values | Security review runs | The client/server boundary is evaluated | Secret exposure is a blocker under repository policy |
| User-controlled content | A UI renders user-controlled content | Security review runs | Escaping or sanitization evidence is checked | Missing boundary protection is reported |
| Skill routing change | Routing, activation, command, or reference-loading rules change | Skill validation runs | The validation matrix is loaded | Required routing scenarios are executed or explicitly reported unavailable |
| Tester Phase 1 stack-neutral artifact | Test Cases are drafted for an owning repository scope | Tester produces Phase 1 output | The case records scope, level, behavior, artifact, and runner | No C#-specific artifact shape is imposed |
| Tester Phase 2 command attribution | Executable tests are implemented for an evidenced scope | Tester reports Phase 2 validation | Command attribution is complete | Package manager or tool, exact command, category, evidence, result, scope, and working directory are retained |
| Source-repo Codex invocation | Work runs in the Lillian source repo | Skill is invoked | Source path is available | `web-frontend-development/SKILL.md` is valid |
| Global-symlink consumer invocation | A consumer exposes Lillian skill paths through supported project wiring | Skill is invoked | Project skill path resolves to Lillian source | The skill loads through the configured project path |
| `.ai` vendored invocation | A consumer vendors Lillian under `.ai` | Skill is invoked through copied or linked project sources | Source path is resolvable | The skill loads from the vendored or copied project source |
