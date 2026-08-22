# Node.js Profile

Activate only when the owning scope has an explicit `package.json`, declared Node workspace, or Node runtime/package
configuration. A package manifest establishes a Node package scope; browser-facing framework guidance remains owned by
the applicable frontend profiles.

Durable guidance:

- Preserve each npm, pnpm, Yarn, Bun, Nx, or Turborepo workspace and package boundary.
- Resolve the package manager from valid `packageManager` metadata, workspace configuration, a consistent lockfile, or
  supporting CI evidence in that order.
- Document Node runtime evidence such as `engines.node`, `.nvmrc`, `.node-version`, Volta, CI setup, or toolchain
  configuration when it belongs to the owning scope.
- Document build, type-check, lint, format, test, package, and run commands only when declared by package scripts,
  project configuration, workspace targets, or CI.
- Preserve exact commands, package manager, scope, and working directory. Never translate commands between npm, pnpm,
  Yarn, and Bun.
- Keep browser-facing React, Next.js, Angular, and other frontend scopes separate from Node runtime, backend, CLI,
  worker, service, or library scopes.

Do not activate Node.js from JavaScript or TypeScript extensions, directory names, framework-like scripts, CI commands,
or Dockerfiles alone. Do not invent a default command when the owning package has no command evidence.
