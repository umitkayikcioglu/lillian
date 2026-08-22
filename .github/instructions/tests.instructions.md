---
applyTo: "**/*Tests*/**,**/tests/**,**/__tests__/**,**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx,**/*.test.js,**/*.test.jsx,**/*.spec.js,**/*.spec.jsx,**/test_*.py,**/*_test.py,**/tests/**/*.py,**/*.Tests.cs,**/*Tests.cs"
---

# Test Instructions

This file identifies test context only. It does not select a test framework by path.

Resolve the owning scope from repository evidence before applying test standards. Do not infer a test framework from path names.

1. **.NET scope:** use the nearest owning `.csproj`; treat `.sln` as solution grouping or supporting evidence, not direct per-file ownership.
2. **Activated frontend scope:** use the nearest relevant `package.json`, workspace project, Angular project, or Nx project.
3. **Ambiguous ownership:** when ownership cannot be resolved, report the scope as unresolved and do not guess a framework.

In mixed monorepos, resolve test policy independently per project or package scope.

Test-project placement/naming and HTTP-file placement/naming come from
[`Canonical test project and HTTP file naming`](../skills/solution-structure/SKILL.md#canonical-test-project-and-http-file-naming).

## .NET scope

For .NET scopes, follow `.github/CONTRIBUTING.md` (`.NET Testing`) and the conventions below.

### Framework and isolation

- Use **MSTest** only; do not introduce xUnit or NUnit.
- Keep tests deterministic and isolated. Do not depend on execution order or shared mutable state.
- Test application behavior, not framework behavior.

### Test method naming

Use `{Method}_{Scenario}_{Expected}` for test method names.

### Unit tests

- Use fakes or mocks for dependencies.
- Focus on domain logic, edge cases, and failure paths.

### Integration tests

- Use **Testcontainers** when behavior depends on an external database, queue, cache, broker, or other provider.
- An EF Core test may use an isolated in-memory database only when provider-specific behavior is explicitly out
  of scope. Use the real provider through Testcontainers when SQL translation, constraints, transactions,
  concurrency, or provider behavior matters.
- When a test builds an application service provider or host, reproduce the production registration and
  configuration closure for every service under test. Registering an interface is insufficient when its
  implementation also requires options, cache, telemetry, or another prerequisite. Resolve every service under
  test during fixture startup so missing composition fails before test execution.

### Application test boundary ownership

- Use `WebApplicationFactory<TEntryPoint>` to exercise one ASP.NET Core deployable in-process, with every
  test-only substitution at an external process or resource boundary made explicit.
- Use `Aspire.Hosting.Testing` for closed-box E2E tests that exercise multiple processes or orchestrated
  resources through their public boundaries.
- Use both layers when both scopes exist, but assign every scenario to exactly one owning layer. A scenario
  **MUST NOT** be duplicated between `WebApplicationFactory` and Aspire tests.
- Put broad process-local behavior in `WebApplicationFactory` tests. Keep Aspire E2E coverage thin and limited
  to critical cross-process or cross-resource paths.
- Apply the endpoint scenarios defined by
  [`Deployable-process HTTP endpoints`](csharp.instructions.md#deployable-process-http-endpoints) without
  restating their response contracts. When a Gateway proxies those Host endpoints, Aspire E2E owns anonymous
  `/ping` and unauthenticated `/me` traversal through the public Gateway, while Host
  `WebApplicationFactory` owns authenticated `/me` projection. The WAF substitution **MUST** replace only the
  external identity-provider token-validation boundary while retaining the real application authentication and
  authorization pipeline. Do not duplicate those scenarios across layers. When no Gateway participates, assign
  each applicable scenario once at the nearest public boundary.
- Do not move module or service behavior into a Host test merely to prove that the runner started.

### Options validation tests

- Test property-level data annotations independently from cross-property or `IValidatableObject` invariants.
- Keep every property-level value valid in the cross-property case so object-level validation is guaranteed to
  run.

### Additional test types

- Add API contract tests when an API contract is in scope.
- Add property-based tests for parsers when they materially improve input-space coverage.
- Add a basic load smoke test for a critical path when performance or stability risk warrants it.

## Other scopes

For activated frontend scopes, use `.github/skills/web-frontend-development/SKILL.md`.

For activated Node.js scopes, use `.github/skills/node-development/SKILL.md`.

For activated Python scopes, use `.github/skills/python-development/SKILL.md`.
