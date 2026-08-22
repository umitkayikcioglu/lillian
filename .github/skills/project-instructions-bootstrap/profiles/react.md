# React Profile

Activate only from a declared `react` dependency or peer dependency.

Durable guidance:

- Apply React guidance only to scopes whose package manifest definitively declares React.
- Preserve framework-specific validation commands exactly as declared by scripts or CI.
- Keep component, styling, and testing standards durable and generic unless the repository declares stricter conventions.
- Treat JSX, TSX, Vite, Next, or other config files as supporting evidence only unless the React dependency is declared.

Do not activate from `.jsx`, `.tsx`, file names, or directory names alone.
