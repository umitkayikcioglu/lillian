# Next.js Reference

This reference owns Next.js router, server/client, data, caching, metadata, route handler, runtime, deployment, and Next.js-specific testing guidance.

## Activation and Router Mode

- Apply only when the relevant package declares a `next` dependency.
- Detect App Router from `app/` or `src/app/` after activation.
- Detect Pages Router from `pages/` or `src/pages/` after activation.
- Treat both router trees as mixed or migration state; preserve boundaries.

## Server and Client Boundaries

- Respect server component and client component boundaries.
- Do not move code across server/client boundaries without checking imports, runtime APIs, and environment variable exposure.
- Keep browser-only APIs out of server-only code and server secrets out of client bundles.
- Apply [frontend-security.md](frontend-security.md) for client/server boundaries, request security, dependency approval, accessibility, and performance applicability.

## Data, Caching, and Runtime

- Use repository and framework-version evidence for data fetching, caching, route handlers, metadata, and runtime behavior.
- Do not assume a router, runtime, or deployment target without repository evidence.
- Preserve existing environment variable conventions.

## Next.js-Specific Tests

- Cover App Router and Pages Router behavior according to the activated router mode.
- Test server/client boundary behavior, route handlers, loading/error/not-found boundaries, and runtime-sensitive code using existing repository conventions.
- Do not duplicate cross-framework test quality rules from `testing.md`.
