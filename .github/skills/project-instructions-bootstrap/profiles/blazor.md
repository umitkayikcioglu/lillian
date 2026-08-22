# Blazor Profile

Activate only from explicit Blazor project evidence such as a Blazor SDK, package, framework reference, or project configuration.

Durable guidance:

- Apply Blazor guidance only to scopes with definitive Blazor evidence.
- Keep UI framework rules in `.github/CONTRIBUTING.md`.
- Preserve project-specific UI conventions if they already exist.
- Document Blazor validation commands only when discovered from project configuration, repository scripts, or CI.

Do not activate from `.razor` files, `wwwroot`, or directory names alone.
