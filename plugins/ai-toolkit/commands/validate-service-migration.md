---
description: Production-gate validation that a migrated .NET service preserves behavior exactly
---

# Service Migration Validator

## Variables
If any of these values were not provided in the invocation, ask the user for them before starting:

- **Service name:** `{ServiceName}`
- **Repository name:** `{RepositoryName}` — repository containing the migrated service
- **Owning project name:** `{OwningProjectName}` — complete canonical project name, not the repository name
- **Old service path:** `{OldServicePath}` — actual production/original path relative to the repository root
- **New service path:** `{NewServicePath}` — actual migrated path relative to the repository root

---

You are validating the migration of `{ServiceName}` in the `{RepositoryName}` repository and
`{OwningProjectName}` project. The service moved from `{OldServicePath}` to `{NewServicePath}` to match current
architecture standards.

## Critical Deployment Rule
Treat this validation as a **production deployment gate**.

- If your verdict is **PASS**, the service will be deployed to production.
- You must be conservative and exhaustive.
- If anything is unclear, missing, or not provably equivalent, return **FAIL** or **ESCALATE**.
- Never assume equivalence without explicit evidence.

## Skills to Apply
Before starting, load and follow these skill files:

- `${CLAUDE_PLUGIN_ROOT}/skills/solution-structure/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/dotnet-service-generator/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/observability/SKILL.md`
- Every dotnet-service-generator reference selected by the migrated service's actual capabilities

## Validation Approach
Analyze from two independent angles — a technical-architecture equivalence pass, and an adversarial pass actively looking for reasons to FAIL — and reconcile both before issuing a verdict. Use parallel subagents for the two angles if your platform supports them.

## Context
You are **only validating the migration of `{ServiceName}`** from `{OldServicePath}` to
`{NewServicePath}`. This is a structural modernization, not a functional change.

## Validation Standard (Fail-Closed)
Use a fail-closed model:

- **PASS** only when equivalence is proven with evidence.
- **FAIL** when any behavior mismatch, missing path, or unverified critical behavior exists.
- **ESCALATE** when you cannot prove equivalence because of ambiguity, missing files, dynamic/runtime-only behavior, or insufficient context.

Do not optimize for speed. Optimize for certainty.

## Task
Validate that the migration from `{OldServicePath}` to `{NewServicePath}` in `{OwningProjectName}` is correct by:

1. **Compare business logic**: Ensure all domain logic, calculations, workflows, and business rules from the old service are present and unchanged in the new service
2. **Compare error handling**: Verify that all exception handling, validation logic, and error cases from the old service are preserved in the new service with equivalent behavior
3. **Verify dependencies**: Confirm that all external dependencies (database, APIs, services) are correctly wired by comparing injection patterns and initialization
4. **Compare request/response flow**: Ensure the selected API adapter/protocol, request handling, response
   generation, and transformations remain behaviorally equivalent
5. **Validate state management**: Confirm that any state, caching, or data persistence patterns are preserved

## Exhaustive Coverage Requirements
You must explicitly cover all of the following:

1. **Entrypoints coverage**
- Enumerate every public entrypoint in the old service (endpoints, handlers, consumers, jobs, command/query handlers, public service methods)
- Map each entrypoint to its new equivalent, or mark as MISSING

2. **Branch and edge-case coverage**
- For each mapped entrypoint, verify all meaningful branches: success path, validation failure, dependency failure, timeout/cancellation, not-found/conflict, and retry/fallback behavior (if present)
- Confirm null/empty/default/boundary input behavior matches

3. **Error contract coverage**
- Map each thrown/returned error category from old to new
- Verify exception type/category, status code/result type, and user-facing/internal message intent are equivalent

4. **Side-effect coverage**
- Verify write operations, event publishing, outbound calls, and persistence side effects are preserved
- Confirm ordering of side effects when order matters

5. **Data transformation coverage**
- Verify all mappings and transformations (request-to-domain, domain-to-persistence, domain-to-response)
- Confirm defaults, normalization, rounding, and precision-sensitive logic are unchanged

6. **Dependency behavior coverage**
- Confirm all critical dependencies from old service exist in new service with equivalent usage semantics
- Validate retries, timeouts, and fallback behavior where applicable

7. **API adapter and protocol coverage**
- Identify the old and new adapter for every API surface and apply the exact required-verification contract from
  its selected generator reference; do not treat different adapters as interchangeable
- Treat removal, narrowing, or semantic alteration of any reference-required protocol capability as a behavior
  change

## What NOT to validate
- Code style or formatting differences
- Performance optimizations beyond the expected improvements
- Re-litigating the approved directory structure or file organization. Use solution-structure and
  dotnet-service-generator only to resolve the supplied paths, projects, filenames, and namespaces; this
  production gate focuses on behavioral equivalence.

## What TO validate about logging/observability
- **Existing logging** from the old service is preserved in the new service
- **Existing observability hooks** (metrics, traces) are present in the new service
- **New logging/observability additions** are acceptable enhancements, NOT replacements for old ones
- Check that log levels, message content, and context are equivalent or improved

## PASS Criteria (All Required)
Return **PASS** only if all are true:

1. Every old entrypoint is mapped to a verified equivalent in the new service
2. No missing business rule, branch, or side effect
3. Error handling behavior is equivalent for all critical paths
4. Existing logging/observability behavior is preserved (or improved without loss)
5. No unresolved questions remain
6. Evidence table is complete and specific
7. Every selected API adapter and exposed protocol behavior is proven equivalent

If any item above is false, do not return PASS.

## Automatic FAIL Triggers
Return **FAIL** immediately if any of the following is found:

- Any old entrypoint has no verified new equivalent
- Any business rule differs without explicit approved change
- Any critical error path is missing or behaviorally different
- Any security/authorization/tenant-isolation validation is missing
- Any side effect is removed, reordered unsafely, or changed semantically
- Any existing logging/trace/metric signal is silently dropped
- Any API adapter is replaced, or any exposed protocol behavior is removed or narrowed, without an explicitly
  approved behavioral change

## Automatic ESCALATE Triggers
Return **ESCALATE** if you cannot conclusively verify due to:

- Incomplete code visibility
- Runtime-only behavior not inferable from source
- Ambiguous mapping where multiple new paths could correspond to one old path
- Missing test evidence for high-risk critical paths

## Output Format
Provide:
1. **Validation Verdict**: PASS / FAIL / ESCALATE
2. **Confidence Level**: High / Medium / Low (PASS requires High)
3. **Entrypoint Equivalence Matrix**:
	- old entrypoint
	- new entrypoint
	- status: EQUIVALENT / DIFFERENT / MISSING
	- evidence: files/functions/tests reviewed
4. **Business Logic Equivalence Matrix**:
	- old rule/flow
	- new rule/flow
	- status and evidence
5. **Error Handling Equivalence Matrix**:
	- old error path
	- new error path
	- status and evidence
6. **Logging/Observability Equivalence Matrix**:
	- old signal
	- new signal
	- status and evidence
7. **API Adapter/Protocol Equivalence Matrix**:
	- old entrypoint and adapter/protocol behavior
	- new equivalent
	- status and evidence for every check required by the selected adapter reference
8. **Issues Found**:
	- severity: Blocker / Major / Minor
	- impact if deployed
	- exact old -> new location mapping
9. **Unresolved Questions**:
	- if non-empty, verdict cannot be PASS
10. **Production Sign-off Statement**:
	- explicit statement whether deployment is safe now
