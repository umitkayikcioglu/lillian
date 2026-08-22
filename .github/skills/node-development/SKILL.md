---
name: node-development
description: Node.js backend, CLI, service, and package-workspace development guidance with manifest-first scope detection and repository-defined validation.
type: guidance
applies_to:
  - Planner
  - Architect
  - Developer
  - Reviewer
  - Tester
  - Documenter
mandatory: conditional
mandatory_when:
  - Implementing or reviewing Node.js backend, CLI, service, or library code
  - Resolving JavaScript or TypeScript runtime, package, workspace, or build validation
  - Working with npm, pnpm, Yarn, Bun, Nx, or Turborepo Node scopes
triggers:
  - Node.js
  - Nodejs
  - Node backend
  - Node service
  - Node CLI
  - npm
  - pnpm
  - Yarn
  - Bun
  - Express
  - Fastify
  - NestJS
references:
  - ../web-frontend-development/references/workspace-routing.md
  - ../web-frontend-development/references/package-management.md
  - ../web-frontend-development/references/validation-output.md
  - references/validation-scenarios.md
summary: Node.js backend, CLI, service, and package-workspace development with manifest-first scope detection and repository-defined validation.
---

# Node.js Development

Use this skill for Node.js runtime work: backend services, HTTP APIs, workers, CLIs, libraries, and JavaScript/TypeScript packages that execute outside the browser. For browser-facing React, Next.js, Angular, or other frontend work, also use `web-frontend-development`; do not use this skill to activate a frontend framework from filenames alone.

## Discovery

Start from manifests and configuration before source files:

1. Identify the repository root and the owning `package.json` or declared workspace package.
2. Resolve workspace membership from `package.json`, `pnpm-workspace.yaml`, Yarn/Bun configuration, Nx, or Turborepo evidence.
3. Resolve the package manager using the shared package-management reference. Preserve the exact manager, working directory, script, and evidence.
4. Inspect Node runtime evidence such as `engines.node`, `.nvmrc`, `.node-version`, Volta configuration, CI setup, or toolchain configuration.
5. Inspect source files only after the owning package and runtime scope are established.

Never infer a package, framework, package manager, or command from a directory name, file extension, or a conventional default. Report ambiguous ownership or conflicting manager evidence without selecting a command.

For shared routing, package-manager, and validation rules, load these references once when the task needs them:

- [workspace routing](../web-frontend-development/references/workspace-routing.md)
- [package management](../web-frontend-development/references/package-management.md)
- [validation output](../web-frontend-development/references/validation-output.md)
- [Node.js validation scenarios](references/validation-scenarios.md)

## Framework and Tool Activation

Activate a Node framework only from effective dependency, peer dependency, project configuration, or declared script evidence in the owning scope. Examples include Express, Fastify, NestJS, Koa, Hapi, and Node's built-in test runner; the list is not a mandate to install or prefer any tool.

For TypeScript, load TypeScript guidance only when the owning scope has `tsconfig*.json` or effective `typescript` dependency evidence. For browser frameworks, hand framework-specific guidance to `web-frontend-development` after its definitive evidence checks.

## Validation

Resolve and report lint, format check, type-check, unit tests, integration tests, end-to-end tests, build, security, and performance independently. Use scripts, project targets, or exact CI commands from the owning package. Do not invent `npm`, `pnpm`, `yarn`, `bun`, framework, or test-runner commands.

Use the canonical validation fields from `web-frontend-development/references/validation-output.md`: scope, working directory, owner, runtime, package manager/environment, framework evidence, category, exact command or `not configured`, evidence, result, and blocker status. Missing capability is `not configured`, never `passed`.

If dependency installation would change a lockfile, stop and request approval before installing. Do not run repository-wide mutating formatters or auto-fix commands by default.

## Engineering Boundaries

- Validate request and message inputs at service boundaries.
- Keep server-only secrets and unrestricted environment values out of browser bundles and logs.
- Handle rejected promises and async errors deliberately; do not swallow them.
- Use timeouts, retry policies, and circuit breakers when calling remote dependencies, following the repository's existing conventions.
- Preserve graceful shutdown and resource cleanup for servers, workers, streams, and child processes.
- Use structured logs and existing tracing/metrics conventions for critical operations.
- Do not add a dependency or test tool without approval under `.github/CONTRIBUTING.md`.

## Testing

Use the test framework and scripts already declared by the owning package. Keep tests deterministic, isolated, and behavior-focused. Await asynchronous work explicitly and control network, timers, storage, and concurrency at external boundaries.
