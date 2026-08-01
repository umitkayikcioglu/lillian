# Angular Profile

Activate only from `angular.json` or a declared `@angular/core` dependency.

Durable guidance:

- Keep guidance version-neutral.
- Apply Angular guidance only to scopes with definitive Angular evidence.
- Preserve Angular CLI or workspace commands exactly as declared by scripts, configuration, or CI.
- Treat component file names and directory conventions as supporting evidence only.
- Do not introduce legacy, version-specific, or migration-era Angular rules unless the consuming repository already documents them.

Do not activate from `*.component.ts`, source extensions, or directory names alone.
