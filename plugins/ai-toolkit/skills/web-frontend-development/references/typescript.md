# TypeScript Reference

This reference owns TypeScript type-system and compiler guidance.

## Compiler and Strictness

- Preserve existing `tsconfig*.json` strictness and compiler options unless an approved plan explicitly changes them.
- Do not automatically enable stricter compiler options in an existing project without impact analysis.
- Report TypeScript compiler errors using the canonical severity policy in `.github/CONTRIBUTING.md`.
- Treat generated types according to repository generation ownership; do not hand-edit generated files.

## Type Safety

- Avoid unjustified `any`; prefer precise types, generics, discriminated unions, and `unknown` with narrowing.
- Use type assertions only when runtime evidence or external contract constraints justify them.
- Preserve public type contracts and avoid widening exported types without a compatibility reason.
- Prefer immutable data shapes where they reduce mutation risk and match repository conventions.

## Async and Boundaries

- Handle async errors deliberately; do not silently drop promises.
- Keep module boundaries consistent with the existing application architecture.
- Do not force a universal folder structure on existing projects.
