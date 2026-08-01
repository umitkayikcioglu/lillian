# React Reference

This reference owns React component, hook, state, effect, rendering, accessibility, and React-specific testing guidance.

## Components and State

- Keep components focused on a clear responsibility.
- Prefer composition over large condition-heavy components.
- Preserve the repository's existing state-management approach; do not introduce a universal state library.
- Keep state ownership near the component or boundary that needs it.

## Hooks and Effects

- Follow hook rules and dependency requirements.
- Keep side effects controlled, explicit, and cleanup-safe.
- Use memoization only when it has a clear correctness or performance reason.

## Rendering and Accessibility

- Provide loading, empty, and error states for user-facing asynchronous flows.
- Preserve the existing styling system.
- Build accessible interactions with semantic elements, labels, focus behavior, and keyboard support.

## React-Specific Tests

- Test user-observable component behavior, state transitions, events, and rendering outcomes.
- For hooks, test public behavior through an existing repository-approved test harness.
- Do not duplicate cross-framework test quality rules from `testing.md`.
