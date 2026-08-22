---
description: "Standalone deep-dive audit across 8 quality dimensions, using the workflow Reviewer's severity scale"
---

# Comprehensive Code Review

Perform a deep, thorough code review examining all aspects of code quality.

This is the **standalone deep audit** — for the workflow review gate, use `/code-review` instead. Load `${CLAUDE_PLUGIN_ROOT}/agents/workflow-reviewer.md` first: its severity scale (Blocker/Major/Minor) and output contract apply here too; the dimensions below define the audit's breadth, not a different vocabulary.

## Scope

Identify the code to review (files, PR, or specified scope).

## Review Dimensions

### 1. Code Quality
- Readability and clarity
- Naming conventions from the applicable owner; use `solution-structure` for physical project and file names
- Code organization and structure
- DRY principle adherence
- SOLID principles adherence
- Appropriate abstractions

### 2. Security
- Input validation and sanitization
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization checks
- Sensitive data exposure
- Secrets in code

### 3. Error Handling
- Exception handling completeness
- Error messages (informative but not leaking internals)
- Graceful degradation
- Retry logic where appropriate
- Transaction rollback handling

### 4. Performance
- N+1 query problems
- Unnecessary allocations
- Missing indexes (for new queries)
- Caching opportunities
- Async/await correctness
- Resource disposal

### 5. Observability
- Logging at appropriate levels
- Structured logging with context
- Metrics instrumentation
- Trace propagation
- Health check coverage

### 6. Architecture
- Clean architecture boundaries
- Domain logic in correct layer
- Dependency direction
- Interface segregation
- Coupling and cohesion

### 7. Testing
- Unit test coverage for new code
- Edge cases covered
- Test determinism
- Mock/fake appropriateness

### 8. Standards Compliance
- `.github/CONTRIBUTING.md` adherence
- Every matching `.claude/rules/*.md` applied correctly
- Applicable skills from `${CLAUDE_PLUGIN_ROOT}/skills/INDEX.md` applied correctly

## Output Format

Use the output contract from `workflow-reviewer.agent.md` — Verdict (PASS/FAIL), findings grouped by Blocker/Major/Minor with file:line references, Fix Checklist on FAIL, up to 5 optional improvements on PASS — with two adaptations for this deep audit:

- Tag every finding with its dimension from the list above (e.g., `[Security]`, `[Performance]`).
- Security findings are always **Blocker**.

### Summary

[1-2 sentence overall assessment before the verdict]
