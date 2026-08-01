# Frontend Quality Reference

This reference owns frontend validation lifecycle, command execution, suppression policy, reporting, and mutation controls.

## Authoritative Configuration

Repository configuration is authoritative for linting and formatting. Evidence may include package scripts, CI workflows, ESLint flat or legacy configuration, Biome configuration, Prettier configuration, Angular ESLint configuration, TypeScript configuration, workspace or task-runner configuration, repository ignore files, and tool-specific ignore configuration.

- Use the configured tools and rules; do not replace them with preferred alternatives or silently add or strengthen rules outside approved scope.
- Honor repository and tool exclusions. Generated, vendored, build, cache, coverage, and dependency outputs remain excluded when configuration excludes them, even when they appear in a Git diff.
- If repository configuration intentionally includes generated or vendored files, report that evidence before validating them.
- If scripts, CI, and tool configuration conflict about tools or exclusions, report ambiguity rather than choosing silently.

## Validation Categories

Resolve and report separately:

- lint
- format check
- type-check
- unit tests
- component tests
- integration tests
- end-to-end tests
- build

Do not treat "not configured" as "passed." Never invent missing commands.

## Lint Severity

Apply the canonical frontend severity policy from `.github/CONTRIBUTING.md`.

- Report missing lint evidence when a verified lint command exists; if CI requires lint, the missing gate blocks completion.
- Lint configuration without a script: report missing command.
- No lint tooling: report missing capability.

Do not install lint tooling automatically.

## Suppression Policy

The following require the narrowest possible scope, specific justification, and a tracking reference where repository policy requires one:

- `eslint-disable`
- `eslint-disable-next-line`
- `@ts-ignore`
- `@ts-expect-error`
- `@ts-nocheck`
- Angular template suppressions
- test-only suppressions

Classify suppression findings using the canonical frontend severity policy in `.github/CONTRIBUTING.md`.

## Formatting Safety

- Prefer non-mutating format checks.
- Do not run repository-wide mutating formatters or auto-fix commands by default.
- When a formatter is intentionally run, constrain it to approved changed files.
- Inspect the resulting diff and stop if unrelated files changed.
- Keep unrelated formatting churn out of feature changes.

## Validation Reporting

For every command, report scope, working directory, package manager, exact command, evidence source, category, and result. Report environment or external-service prerequisites when they prevent execution.
