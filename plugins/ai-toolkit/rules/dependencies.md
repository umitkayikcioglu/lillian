---
trigger: glob
globs: **/*.csproj
---

# Dependency Instructions

This file is the canonical authority for changing project dependencies.

- Obtain approval before adding any third-party dependency.
- Before adding custom code or a new dependency, inspect existing project/package references and the approved
  shared-library catalog in `../skills/INDEX.md`; reuse a compatible approved capability when available.
- Minimize dependencies, especially across domain boundaries.
- Verify compatibility, license, and maintenance status before changing any `PackageReference`.
