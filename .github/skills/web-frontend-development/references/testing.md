# Frontend Testing Reference

This reference owns cross-framework frontend test quality. Framework references own only framework-specific testing concerns.

## Test Boundaries

- Unit tests cover isolated logic and small behavior units.
- Component tests cover rendered component behavior and user interactions.
- Integration tests cover collaboration between local modules or framework boundaries.
- End-to-end tests cover critical user journeys through the running application.

## Quality Standards

- Test observable behavior instead of implementation details.
- Keep tests deterministic, isolated, and repeatable.
- Avoid relying on execution order, real time, network availability, or shared mutable state unless the repository test harness explicitly controls them.
- Use mocks and test doubles at external boundaries; avoid mocking the behavior under test.
- Await asynchronous behavior explicitly and avoid arbitrary sleeps.
- Prevent flaky tests by controlling timers, network, storage, and concurrency.
- Include accessibility checks where the repository has an existing accessibility test convention or the change affects interaction semantics.
- Use snapshots sparingly; snapshots must be small, intentional, and reviewed as behavior contracts.
- Interpret coverage as supporting evidence, not proof of correctness.
- Follow repository naming and organization conventions.
- Reuse the repository's existing test framework and scripts.
- Follow `.github/CONTRIBUTING.md` dependency-approval policy before adding or changing test tooling.
