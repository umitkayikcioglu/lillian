# Angular Reference

This reference owns Angular architecture, dependency injection, templates, routing, forms, change detection, and Angular-specific testing guidance.

## Architecture Detection

- Apply only when `angular.json` exists or the relevant scope declares `@angular/core`.
- Detect standalone architecture from `standalone: true`, `bootstrapApplication`, or standalone route imports.
- Detect module-based architecture from `NgModule`, module declarations, or module imports.
- Treat both patterns as mixed architecture; preserve existing boundaries.

## Multi-Project Ownership

For an activated Angular workspace:

1. Read `angular.json` and record every declared project's name, project type, root, source root, targets or architect entries, configurations, and explicitly declared default project.
2. Assign a touched file to the project with the most specific matching root or source root.
3. Do not select the default project when the touched path belongs to another declared project.
4. Resolve lint, test, build, serve, and other commands only from the owning project's declared targets and repository scripts.
5. Do not assume root-level commands or a target declared by one project apply to siblings.
6. Preserve separate validation results for each touched project. Include another project only when a declared dependency or repository gate requires it.
7. Report overlapping roots, unresolved ownership, or conflicting target evidence as ambiguity.

## Angular Patterns

- Use repository evidence and version information before applying version-specific guidance.
- Preserve dependency injection boundaries.
- Keep signals, RxJS, and state ownership aligned with existing project conventions.
- Preserve template type safety, forms strategy, routing patterns, and change-detection approach.

## Angular-Specific Tests

- Use TestBed or the repository-equivalent convention already present.
- Cover components, services, DI behavior, templates, router behavior, forms, signals, and RxJS flows as appropriate.
- Do not duplicate cross-framework test quality rules from `testing.md`.
