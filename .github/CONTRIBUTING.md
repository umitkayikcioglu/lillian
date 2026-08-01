# Contributing Guidelines

This document defines the **canonical engineering, architecture, and quality standards**
for all contributions to this repository.

If there is any conflict between this file and other documentation, **this file wins**.

> _Always leave the code better than you found it!_

---

## Priority Framework (Tradeoffs)

When making decisions or reviewing changes, priorities are ranked as follows:

1. **Data**
   - Accuracy, integrity, correctness, and safety are non-negotiable.
2. **Functionality**
   - Keep It Super Simple (KISS). Solve the problem, nothing more.
3. **User Experience**
   - Follow existing patterns. Consistency over novelty.
4. **Performance & Stability**
   - Observability, resilience, and predictable behavior.
5. **User Interface**
   - Clean, standard, accessible. No unnecessary customization.

---

## Code Review Checklist

### Must Have

- **Observability**
  - Structured logging with event IDs
  - Tracing and metrics for critical operations
- **Transactional integrity**
  - Operations must be atomic, retry-safe, or compensating
- **Resilience**
  - Timeouts, retries with exponential backoff and jitter
  - Circuit breakers for remote dependencies
- **Correctness**
  - Input validation at boundaries
  - Domain invariants enforced
- **Architecture**
  - Clean boundaries
  - Domain layer persistence-agnostic and framework-free
- **Scope discipline**
  - Only purpose-driven changes
  - No unrelated edits mixed into a change

---

## Naming Standards

- Descriptive, intention-revealing names
- Full words, no abbreviations
- Comments only for non-obvious decisions
- MSSQL:
  - PascalCase
  - Singular table names
  - No prefixes, no abbreviations

---

## Comments and TODOs

- Do **not** restate obvious code
- Explain business logic and non-obvious tradeoffs
- Preserve license and architectural decision comments
- TODOs **must** reference a tracking item using this format:

```csharp
// TODO ISSUE https://<link> <short description>
````

---

## UI Standards

Apply UI standards by repository scope.

### Blazor UI

* **FluentUI Blazor** or **Tailwind CSS** exclusively — one framework per Blazor project, do not mix
* No custom CSS, JavaScript, or fonts unless explicitly approved
* Follow:

  * [https://www.fluentui-blazor.net/](https://www.fluentui-blazor.net/)
  * [https://fluent2.microsoft.design/](https://fluent2.microsoft.design/)
  * [https://tailwindcss.com/docs](https://tailwindcss.com/docs)

### Frontend UI

* For TypeScript, React, Next.js, and Angular scopes, follow the repository's existing styling system and component architecture.
* Do not introduce a new styling framework, component library, custom font, or JavaScript utility dependency without explicit approval.
* Preserve accessibility semantics, keyboard behavior, focus behavior, and loading/error states for user-facing changes.

---

## Architecture and Design Principles

### Architectural Boundaries

* Enforce clean architecture boundaries.
* The **Domain layer must be persistence-agnostic and framework-free**.
* Infrastructure concerns (databases, messaging, external services) must not leak into the Domain.
* Dependencies must always point inward.

### Guiding Philosophy

* **Reason from First Principles**:
  * Break problems down to their fundamental requirements.
  * Question assumptions before applying abstractions.
  * Build solutions bottom-up from real constraints.
* Prefer explicit, simple solutions over clever or generic ones.

### Core Principles

* **KISS** – simple beats clever
* **DRY** – eliminate duplication
* **YAGNI** – no speculative features
* **SOLID** – modular and adaptable design

### Pattern Usage

* Use classic GoF patterns only when they reduce complexity
* Apply Domain-Driven Design (DDD) and CQRS only when justified
* Avoid pattern cargo-culting

References:

* https://refactoring.guru/design-patterns/catalog
* https://learn.microsoft.com/azure/architecture/patterns/

---

## Concurrency and Async

* Assume multithreaded execution
* Use async I/O end-to-end
* CancellationToken is required on all public async APIs
* No blocking calls on async paths

---

## Exceptions and Errors

* Define domain, transient, and fatal exception categories
* Never swallow exceptions
* No catch-all without rethrow
* HTTP APIs must map errors to ProblemDetails

---

## Performance

* Profile before optimizing
* Remove synchronous I/O
* Reduce allocations
* Avoid LINQ in hot paths unless measured

---

## Nullability and Immutability

* Nullable reference types enabled
* Prefer immutable records for DTOs and value objects

---

## Persistence

* EF Core with explicit tracking strategy
* Transactions around multi-aggregate changes
* Indexes must match query shapes
* Avoid hidden N+1 behavior

---

## Caching

* Explicit cache keys, TTLs, and invalidation strategy
* Protect against cache stampede
* Use IDistributedCache for shared caches

---

## Messaging

* Define idempotency strategy
* Use outbox pattern for publishes
* Configure DLQs and document ordering guarantees

---

## Resilience

* Timeouts per call
* Retries with exponential backoff and jitter
* Circuit breakers on remote dependencies

---

## Security

* Validate inputs
* Enforce authorization at handler boundaries
* Never log secrets or PII
* Store secrets in a vault

---

## Configuration

* Do not pass `IConfiguration` into extension methods. Use `BindConfiguration` (bind to strongly-typed options) and pass options instead.
* Options pattern
* Environment-specific config via files or environment variables only
* Feature flags for risky changes


---

## Dependency Management

* **Third-party library approval required** – any new external dependency is subject to approval before being added
* **Prefer workspace libraries** – use existing shared libraries in `common-libraries/` instead of writing custom implementations. The canonical library table (name, purpose, README) lives in `.github/skills/INDEX.md` — check it before adding any dependency
* Minimize dependencies, especially in Domain layer
* Vet licenses and maintenance status before adding dependencies

---

## Observability

* Structured logs
* OpenTelemetry traces and metrics
* Correlate logs using trace IDs
* Health, readiness, and liveness endpoints required

---

## APIs

* OpenAPI documented
* Versioned routes
* Consistent paging, sorting, and error schema
* Idempotency keys for POST where appropriate

---

## Time and Money

* Use UTC for storage
* Use `DateTimeOffset` in code
* Use `decimal` for money
* Culture-invariant parsing

---

## Serialization

* System.Text.Json with source generators
* Stable field names
* Backward-compatible DTO changes only

---

## Testing

Apply testing standards by repository scope.

### .NET Testing

* Test framework: **MSTest** only for Lillian .NET scopes.
* Existing xUnit or NUnit usage in a .NET scope is a standards mismatch. Do not migrate test frameworks without explicit scope and approval.
* Unit tests:
  * Use fakes/mocks for dependencies.
  * Focus on domain logic and edge cases.
* Integration tests:
  * For external dependencies (databases, queues, caches, brokers), use **Testcontainers**.
  * For EF Core integration testing, use an **in-memory database**.
* Contract tests for APIs
* Property-based tests for parsers where applicable
* Basic load smoke tests for critical paths

### Frontend Testing

* For TypeScript, React, Next.js, and Angular scopes, use the test framework and scripts already declared by repository evidence.
* Do not introduce Jest, Vitest, Playwright, Cypress, Testing Library, or other test dependencies without explicit approval.
* Follow `.github/skills/web-frontend-development/references/testing.md` for cross-framework frontend test quality.
* Follow framework-specific frontend references only when definitive framework evidence exists.

---

## Code Quality

* .editorconfig enforced
* Analyzers enabled
* Treat warnings as errors
* CI must pass:

  * Tests
  * Formatting
  * Coverage threshold
  * Security scan

### Frontend Validation

For TypeScript, React, Next.js, and Angular scopes, validation commands must be resolved from repository evidence and reported separately:

* lint
* format check
* type-check
* unit tests
* component tests
* integration tests
* end-to-end tests
* build

Never invent missing commands and never treat "not configured" as "passed."

Frontend severity:

* TypeScript compiler errors: **Blocker**
* Lint errors: **Blocker**
* New warnings in changed code: **Major**
* New warnings when repository or CI enforces zero warnings: **Blocker**
* Pre-existing warnings outside changed scope: baseline report only
* Stale `@ts-expect-error`: **Blocker**
* Broad or unjustified suppressions: **Blocker** when hiding type/lint defects or disabling file/project checks; otherwise **Major**

Do not run repository-wide mutating formatters or auto-fix commands by default. Do not install lint, formatter, test, or build tooling without explicit approval.

---

## Deployment

* Minimal container images
* Non-root containers
* Resource limits defined
* Graceful shutdown implemented
* Health probes configured
* Configuration via appsettings.{environmentName}.json

---

## Pre-Commit Checklist

Before pushing:

1. Changes are intentional and scoped
2. Formatting and analyzers are clean
3. Verified locally (Docker Compose or Minikube if applicable)
4. Build and tests pass
5. Documentation updated if behavior changed

---

## Documentation

* ADRs for major decisions
* README includes how to run
* Runbooks document failure modes

---

## Definition of Done

A change is done only when:

* All rules above are satisfied
* Build is green
* Tests cover new behavior
* Documentation is updated where change occurs

---
