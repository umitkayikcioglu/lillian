# Node.js Development Validation Scenarios

Use these scenarios as the minimum routing and validation matrix for `node-development`.

| Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|
| Node backend package | An owning `package.json` declares a Node runtime package and backend dependency | Discovery runs | Node development activates | Node guidance and shared validation output load |
| TypeScript Node service | A package has `tsconfig.json`, `typescript`, and a server dependency | A `.ts` service changes | Node and TypeScript evidence are resolved | Backend scope is not treated as browser-only frontend |
| Node CLI | A package declares a CLI entry point and runtime script | A CLI source file changes | Node scope resolves from package evidence | Exact package script or CI command is preserved |
| Browser frontend package | A package declares React or Next.js and has no Node backend boundary | A component changes | Frontend guidance owns the scope | Node backend guidance is not used to activate a backend framework |
| Generic JavaScript file | A `server/` directory contains `.js` files but no package or runtime evidence | Discovery runs | Filename and directory are supporting-only | No Node framework or command is guessed |
| Generic workspace ownership | A pnpm, npm, Yarn, or Bun workspace contains multiple Node packages | A file changes inside one package | The most specific package owns the file | Only that package's commands are eligible |
| Root versus package scripts | A workspace has root fan-out scripts and package-local scripts | Validation resolves a package | Script ownership is retained | No package filter or root command is invented |
| Conflicting package managers | A scope has multiple lockfiles without a valid `packageManager` declaration | Command resolution runs | Manager evidence is ambiguous | No manager-specific command is emitted |
| Missing validation script | A package has lint configuration but no script, target, or CI command | Validation resolves lint | Capability and command availability are separated | Result is `not configured`, not `passed` |
| Overlapping package roots | Two package/project roots match a touched file equally | Ownership resolves | The scope is ambiguous | No package or command is selected |
| Client secret boundary | A Node package exposes unrestricted environment values to browser code | Security review runs | Server/client boundary is checked | Secret exposure is a blocker |
