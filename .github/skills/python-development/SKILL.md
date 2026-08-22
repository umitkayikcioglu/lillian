---
name: python-development
description: Python application, API, CLI, library, and packaging guidance with manifest-first project detection and repository-defined validation.
type: guidance
applies_to:
  - Planner
  - Architect
  - Developer
  - Reviewer
  - Tester
  - Documenter
mandatory: conditional
mandatory_when:
  - Implementing or reviewing Python application, API, CLI, worker, or library code
  - Resolving Python environment, package, test, type-check, build, or deployment validation
  - Working with pyproject.toml, requirements files, Poetry, uv, pip-tools, or Pipenv projects
triggers:
  - Python
  - Python API
  - Python CLI
  - Python package
  - FastAPI
  - Django
  - Flask
  - pytest
  - Poetry
  - uv
summary: Python application, API, CLI, library, and packaging development with manifest-first project detection and repository-defined validation.
references:
  - ../web-frontend-development/references/workspace-routing.md
  - ../web-frontend-development/references/validation-output.md
  - references/project-and-tooling.md
  - references/validation-scenarios.md
---

# Python Development

Use this skill for Python applications, HTTP APIs, workers, CLIs, libraries, data-processing packages, and Python distribution projects.

## Discovery

Start from project metadata and environment configuration before source files:

1. Resolve the owning project from the nearest `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements*.txt`, `Pipfile`, or declared workspace/project configuration.
2. Identify Python version evidence from `requires-python`, tool configuration, `.python-version`, CI setup, container configuration, or repository documentation.
3. Identify the environment and package manager from valid project metadata, lockfiles, workspace configuration, and exact CI commands.
4. Inspect source files only after project ownership and tool evidence are established.

Treat these as manager evidence only when they belong to the owning project: `uv.lock`, `poetry.lock`, `Pipfile.lock`, requirements lock/output files, or repository-supported conda/environment files. A parent lockfile does not automatically own a nested standalone project.

When ownership, environment, or package-manager evidence conflicts, report the competing evidence and do not emit a manager-specific command.

Load these references once when the task needs their guidance:

- [Python project and tooling evidence](references/project-and-tooling.md)
- [workspace routing](../web-frontend-development/references/workspace-routing.md)
- [validation output](../web-frontend-development/references/validation-output.md)
- [Python validation scenarios](references/validation-scenarios.md)

## Framework and Tool Activation

Activate FastAPI, Django, Flask, Celery, or another Python framework only when the owning project declares the dependency, configuration, or exact repository command. Do not activate a framework from directory names, module names, or common filenames alone.

Activate pytest, unittest, Ruff, Black, isort, Mypy, Pyright, Pylint, Poetry, uv, pip-tools, Pipenv, or another tool only from owning-project dependency, configuration, script, lockfile, or CI evidence. Never install a preferred tool to fill a missing capability.

## Validation

Resolve and report lint, format check, type-check, unit tests, integration tests, end-to-end tests, build/package, security, and performance independently. Preserve the exact command, project working directory, environment/package manager, and evidence source.

Use the canonical result values and fields from `../web-frontend-development/references/validation-output.md`: scope, working directory, owner, runtime, package manager/environment, framework evidence, category, exact command or `not configured`, evidence, result, and blocker status. A missing command or capability is not a pass.

Do not run repository-wide mutating formatters or dependency installation by default. If installation would create or change a lockfile, stop and request approval first.

## Engineering Boundaries

- Validate external input at API, CLI, task, and message boundaries.
- Keep secrets and personal data out of source, fixtures, logs, traces, and validation output.
- Handle exceptions deliberately; distinguish expected validation failures, transient dependency failures, and fatal process errors.
- Use async I/O without blocking event-loop paths when the project is asynchronous.
- Preserve context managers, cancellation, graceful shutdown, and resource cleanup for files, sockets, database sessions, workers, and subprocesses.
- Use existing repository logging, metrics, tracing, timeout, retry, and configuration conventions.
- Do not add dependencies or test tools without approval under `.github/CONTRIBUTING.md`.

## Testing

Use the owning project's declared test framework and commands. Prefer deterministic behavior tests, isolated fixtures, controlled clocks and external boundaries, and explicit async handling. Do not assume pytest, unittest, or a particular coverage threshold without repository evidence.
