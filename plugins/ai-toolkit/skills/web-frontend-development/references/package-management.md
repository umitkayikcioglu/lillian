# Package Management Reference

This reference owns package-manager, lockfile, and dependency-install mutation rules. Workspace and package/project ownership are defined in [workspace-routing.md](workspace-routing.md). Validation categories and result reporting are defined in [frontend-quality.md](frontend-quality.md).

## Package Manager Resolution

Select package manager per scope using this precedence:

1. A valid `packageManager` field at the owning package or workspace scope.
2. Explicit workspace configuration.
3. One consistent lockfile.
4. CI usage as supporting evidence only.

Supported managers are npm, pnpm, Yarn, and Bun.

A `packageManager` field is valid only when it names one of the supported managers and includes a non-empty, parseable version. Apply the declaration at the nearest owning scope; a root declaration does not override a nested standalone package with its own valid declaration.

## Conflict Behavior

- A valid `packageManager` declaration wins over conflicting lockfiles; report the conflict and retain both pieces of evidence.
- Multiple lockfiles in one scope without a valid declaration are ambiguous.
- Nested standalone packages may use a different package manager.
- CI usage does not override package declarations or lockfiles.
- Ambiguous package-manager evidence must not produce manager-specific verified commands.

Recognize manager lockfiles only within the owning scope: `package-lock.json` for npm, `pnpm-lock.yaml` for pnpm, `yarn.lock` for Yarn, and `bun.lock` or supported legacy Bun lockfiles for Bun. A lockfile in a parent scope is supporting evidence only unless workspace configuration assigns the package to that scope.

## Commands

- Preserve the exact declared script or command.
- Preserve scope and working directory.
- Never translate scripts between npm, pnpm, Yarn, and Bun.
- Never emit framework defaults as verified commands.
- If dependency installation would modify a lockfile, stop and require approval before proceeding.

Keep root fan-out commands separate from package-local commands. Use a filtered command only when the filter is explicitly present in package scripts, workspace configuration, target configuration, or CI evidence.

## Nx Ownership and Commands

Use `nx.json`, a declared `nx` dependency, `project.json`, workspace project declarations, and valid target definitions as Nx evidence.

1. Map a touched file to the most specific project root or explicit source root.
2. Preserve project name and root, then inspect only targets declared for that project.
3. Preserve executor, configuration, target dependencies, working directory, and exact command evidence from repository scripts, CI, or supported Nx invocation configuration.
4. Do not assume every project has `lint`, `test`, `build`, or `e2e` targets.
5. Do not invent `nx run`, `nx affected`, target names, or project selection.
6. Keep validation results separate per project; overlapping ownership is ambiguous.

## Turborepo Ownership and Commands

Use `turbo.json` or another repository-supported Turbo configuration, a declared `turbo` dependency, workspace declarations, and configured tasks as Turborepo evidence.

1. Resolve the owning package from the nearest `package.json` that is a member of the declared workspace.
2. Resolve a task from both Turbo configuration and the owning package's scripts.
3. Preserve package name, workspace root, package working directory, task, dependencies, configuration, filters, package manager, and exact script or CI command.
4. Do not invent filters, translate syntax, or assume every package participates in every task.
5. Keep package attribution even when a root Turbo command orchestrates execution.
6. Report absent or ambiguous task ownership without emitting a verified command.

Angular project ownership and target routing are defined in [angular.md](angular.md). This reference only supplies the package-manager and lockfile evidence used by that routing.
