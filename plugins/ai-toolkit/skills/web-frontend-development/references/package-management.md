# Package Management Reference

This reference owns package-manager, workspace, lockfile, and command execution rules.

## Package Manager Resolution

Select package manager per scope using this precedence:

1. Valid `packageManager` field.
2. Explicit workspace configuration.
3. One consistent lockfile.
4. CI usage as supporting evidence only.

Supported managers are npm, pnpm, Yarn, and Bun.

## Conflict Behavior

- A valid `packageManager` declaration wins over conflicting lockfiles; report the conflict.
- Multiple lockfiles in one scope without a valid declaration are ambiguous.
- Nested standalone packages may use a different package manager.
- CI usage does not override package declarations or lockfiles.
- Ambiguous package-manager evidence must not produce manager-specific verified commands.

## Commands

- Preserve the exact declared script or command.
- Preserve scope and working directory.
- Never translate scripts between npm, pnpm, Yarn, and Bun.
- Never emit framework defaults as verified commands.
- If dependency installation would modify a lockfile, stop and require approval before proceeding.

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

## Angular Workspace Commands

For Angular multi-project workspaces, use `angular.json` project roots, source roots, targets or architect entries, configurations, and repository scripts to preserve project-level command ownership. The most specific project path owns a touched file; an explicit default project is used only when path ownership does not select a different project. Do not apply root Angular commands universally, and report overlapping or unresolved project ownership as ambiguity.
