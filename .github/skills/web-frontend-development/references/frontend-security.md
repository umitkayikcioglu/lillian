# Frontend Security and UX Quality Reference

Apply these checks to user-facing frontend changes and to changes crossing authentication, data, environment, or dependency boundaries. Use repository evidence; do not invent tools or stronger rules.

## Client and Server Boundaries

- Never expose server secrets, private tokens, credentials, or unrestricted environment values in client bundles.
- Keep authorization decisions at the server or API boundary; frontend visibility checks are not authorization.
- Respect framework server/client boundaries and runtime-specific APIs.
- Redact secrets and personal data from test fixtures, logs, screenshots, and validation output.

## Input, Output, and Requests

- Escape or sanitize user-controlled content according to the framework and existing repository pattern.
- Review CSRF, CORS, CSP, cookie, and redirect behavior when the application architecture uses them.
- Preserve existing authentication, authorization, error, and retry boundaries.
- Do not add a new dependency or test tool without following `.github/CONTRIBUTING.md` approval policy.

## Accessibility

For interactive UI, verify:

- semantic controls and accessible labels;
- keyboard operation and visible focus behavior;
- loading, empty, error, and disabled states;
- appropriate status announcements where asynchronous state changes affect users.

Use existing repository accessibility tooling when configured. If no accessibility check exists, report the capability as not configured rather than passing it.

## Performance

- Use repository-defined bundle, build, or performance budgets when available.
- Avoid unnecessary client-side code, data fetching, rendering work, and dependency weight.
- Preserve framework-appropriate caching, image, font, and runtime conventions.
- If no performance command or budget is configured, report it as not configured; do not invent a command.

## Reporting

Report security, accessibility, and performance applicability separately from lint, type-check, tests, and build. Each result must include scope, working directory, exact command or `not configured`, evidence, result, and blocker status as defined by `frontend-quality.md`.
