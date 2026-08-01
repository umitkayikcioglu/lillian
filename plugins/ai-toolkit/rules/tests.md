---
trigger: glob
globs: "**/*Tests*/**, **/tests/**, **/__tests__/**, **/*.test.ts, **/*.test.tsx, **/*.spec.ts, **/*.spec.tsx, **/*.test.js, **/*.test.jsx, **/*.spec.js, **/*.spec.jsx, **/*.Tests.cs, **/*Tests.cs"
---

# Test Instructions

This file identifies test context only. It does not select a test framework by path.

Resolve the owning scope from repository evidence before applying test standards. Do not infer a test framework from path names.

1. **.NET scope:** use the nearest owning `.csproj`; treat `.sln` as solution grouping or supporting evidence, not direct per-file ownership.
2. **Activated frontend scope:** use the nearest relevant `package.json`, workspace project, Angular project, or Nx project.
3. **Ambiguous ownership:** when ownership cannot be resolved, report the scope as unresolved and do not guess a framework.

In mixed monorepos, resolve test policy independently per project or package scope.

For .NET scopes, follow `.github/CONTRIBUTING.md` (`.NET Testing`).

- Test method naming: `{Method}_{Scenario}_{Expected}`
- Project naming: `{Organization}.{Product}.{Area}.{TestType}.Tests`
  - Unit: `MyOrganization.MyProduct.MyArea.Unit.Tests`
  - Integration: `MyOrganization.MyProduct.MyArea.Integration.Tests`
  - End-to-end: `MyOrganization.MyProduct.MyArea.E2E.Tests`

For activated frontend scopes, use `.github/skills/web-frontend-development/SKILL.md`.
