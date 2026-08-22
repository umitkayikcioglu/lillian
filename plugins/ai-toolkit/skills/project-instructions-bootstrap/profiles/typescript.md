# TypeScript Profile

Activate from `tsconfig*.json` or a declared `typescript` dependency.

Durable guidance:

- Treat each TypeScript workspace or package as its own scope.
- Document build, typecheck, lint, format, and test commands only when declared by scripts, tool config, workspace config, or CI.
- Preserve the package manager selected for the scope.
- Do not translate scripts between npm, pnpm, Yarn, or Bun.
- A `tsconfig*.json` file is definitive evidence because it is an explicit compiler/project declaration.

Do not activate from `.ts` or `.tsx` files alone.
