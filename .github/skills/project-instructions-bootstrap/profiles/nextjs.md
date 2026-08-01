# Next.js Profile

Activate only from a declared `next` dependency in the relevant package scope.

Durable guidance:

- Apply Next.js guidance only to scopes with definitive Next.js evidence.
- Treat `next.config.*`, `app/`, `pages/`, middleware, route handlers, and Next-specific scripts as supporting evidence only.
- Preserve App Router, Pages Router, or mixed router boundaries based on repository evidence.
- Preserve Next.js validation commands exactly as declared by scripts, configuration, or CI.

Do not activate from directory names, config files, middleware, route handlers, scripts, or `.tsx` files alone.
