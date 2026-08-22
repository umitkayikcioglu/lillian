# Validation Output Contract

This reference owns the cross-stack validation result shape used by frontend, Node.js, and Python development guidance.

## Categories

Resolve and report these categories independently when applicable:

- lint
- format check
- type-check
- unit tests
- component tests
- integration tests
- end-to-end tests
- build or package
- security
- accessibility
- performance

Use these result values: `passed`, `failed`, `skipped`, `ambiguous`, and `not configured`. A missing capability is never a pass.

## Required Result Fields

| Field | Required content |
|---|---|
| Scope | Repository, workspace, package, project, or solution scope |
| Working directory | Exact command working directory |
| Owner | Package/project name and root |
| Runtime | Browser, Node.js, Python, .NET, or other evidenced runtime |
| Package manager/environment | npm, pnpm, Yarn, Bun, uv, Poetry, Pipenv, pip-tools, conda, or other evidenced environment; otherwise `not applicable` |
| Framework evidence | Evidence path for activated framework(s) |
| Category | Validation category from this reference |
| Command | Exact command or `not configured` |
| Evidence | Manifest, script, target, CI path, or configuration path |
| Result | `passed`, `failed`, `skipped`, `ambiguous`, or `not configured` |
| Blocker | `yes`/`no` and reason |

Every attempted, unavailable, or ambiguous category must retain the owning scope, working directory, exact command or missing status, evidence source, result, and blocker status. Never replace a missing or ambiguous command with a framework default.

## Examples

```text
Scope: node package
Working directory: apps/api
Owner: @company/api (apps/api)
Runtime: Node.js
Package manager/environment: pnpm
Framework evidence: apps/api/package.json -> fastify
Category: type-check
Command: pnpm --filter @company/api typecheck
Evidence: apps/api/package.json -> scripts.typecheck
Result: passed
Blocker: no
```

```text
Scope: Python package
Working directory: services/catalog
Owner: catalog (services/catalog)
Runtime: Python
Package manager/environment: uv
Framework evidence: services/catalog/pyproject.toml -> fastapi
Category: unit tests
Command: not configured
Evidence: services/catalog/pyproject.toml -> dependency-groups.test (no runnable script or CI command)
Result: not configured
Blocker: no — no verified test command exists
```
