# Workspace Routing Reference

This reference owns repository, workspace, package, and project ownership resolution. Package-manager selection and lockfile policy remain in `package-management.md`; validation reporting remains in `frontend-quality.md`.

## Resolution Order

Resolve each touched path independently:

1. Identify the repository root and applicable workspace declarations.
2. Resolve the most specific declared project root or source root.
3. Resolve the owning package from the nearest package manifest that is a declared workspace member or standalone package.
4. Preserve the package/project name, root, and working directory.
5. Report overlapping or unresolved ownership as ambiguous; do not guess a command or framework.

## Workspace Membership Evidence

Use repository evidence such as:

- `package.json` `workspaces` entries or workspace globs.
- `pnpm-workspace.yaml` declarations.
- Yarn workspace configuration.
- Bun workspace configuration or repository-supported workspace declarations.
- Nx `project.json` or workspace project declarations.
- Turborepo workspace membership plus `turbo.json` task configuration.
- Angular project roots and source roots in `angular.json`, when present.

Do not treat a directory name, source extension, or a nearby manifest as proof of ownership when workspace membership is unresolved.

## Generic Workspace Routing

For npm, pnpm, Yarn, and Bun workspaces without Nx or Turborepo routing:

- Map the touched path to the most specific workspace package whose root contains it.
- Keep root-level scripts separate from package-local scripts.
- Preserve an exact root command when it intentionally fans out to packages; do not invent filters.
- Include sibling packages only when a declared script, target dependency, CI gate, or build graph requires them.
- Treat nested standalone packages as independent scopes when their own manifest and manager evidence support that boundary.

## Tool-Specific Routing

- **Nx:** use the owning project root/source root and only its declared targets. Preserve project name, executor, configuration, and target dependencies.
- **Turborepo:** use the owning workspace package and only tasks supported by both Turbo configuration and the package scripts. Preserve filters and package attribution from evidence.
- **Angular:** use `angular.json` project roots and targets when present. Without `angular.json`, use the owning package/project manifest, declared project configuration, and repository scripts; report ambiguity if ownership or targets remain unresolved.

## Effective Dependency Evidence

A framework or tool may be activated from a workspace-root dependency only when:

1. The package is a declared workspace member.
2. The workspace/package manager configuration proves the dependency is available to that package.
3. No package-local evidence contradicts the activation.

Direct package evidence takes precedence for the owning package. Transitive availability alone is not definitive evidence.

## Ambiguity Rules

Stop command selection for a scope when:

- Two package/project roots match with equal specificity.
- A package is not proven to be a workspace member.
- Root and nested package managers conflict without a valid scoped declaration.
- A requested target exists only in a sibling project without a declared dependency.

Report the competing paths, the missing evidence, and the next evidence needed to resolve ownership.
