# CI and Tooling Profile

This profile describes durable command and tooling documentation. It must not activate application framework profiles.

Durable guidance:

- CI commands are command evidence, not framework activation evidence.
- Dockerfiles prove Docker usage only; they do not activate application framework profiles.
- Lint and format tooling must be documented only when declared by scripts, configuration files, dependencies, workspace configuration, or CI.
- Test framework documentation must identify the scope and evidence source.
- Verified command entries must preserve exact command text, package manager, and working directory.
- Framework defaults may be reported as unresolved recommendations, but must not be persisted as verified commands.

Do not infer package manager choice from CI usage alone when package declarations or lock files conflict.
