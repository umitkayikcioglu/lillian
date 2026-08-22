# Python Project and Tooling Evidence

This reference defines Python-specific project, environment, package-manager, and tool evidence. Validation categories and reporting fields are shared with [validation-output.md](../../web-frontend-development/references/validation-output.md).

## Project Ownership Evidence

Use the most specific project boundary supported by repository evidence:

- `pyproject.toml`
- `setup.py` or `setup.cfg`
- `requirements*.txt`
- `Pipfile`
- declared workspace or build configuration
- explicit CI working directories

Do not treat `src/`, `tests/`, `app/`, or a Python filename as project ownership by itself.

## Package and Environment Evidence

Use only evidence belonging to the owning project:

| Evidence | What it can establish |
|---|---|
| `requires-python` | Supported Python version range |
| `uv.lock` | uv-managed dependency resolution |
| `poetry.lock` | Poetry-managed dependency resolution |
| `Pipfile.lock` | Pipenv-managed dependency resolution |
| `requirements*.txt` | Declared pip-compatible requirements, not necessarily a lock |
| `.python-version` | Repository-selected interpreter version |
| CI or container setup | Supporting interpreter/environment command evidence |

If multiple managers or lockfiles apply to one scope without a declared precedence, report ambiguity. Never translate `uv`, Poetry, Pipenv, pip-tools, or pip commands into one another.

## Framework and Tool Evidence

Dependencies and configuration establish tool activation. Scripts and CI establish runnable commands. Source conventions are supporting evidence only.

Examples:

- FastAPI: effective `fastapi` dependency or explicit application configuration.
- Django: effective `django` dependency or Django project configuration.
- Flask: effective `flask` dependency or explicit application configuration.
- pytest: effective `pytest` dependency or exact repository test command.
- Ruff/Black/Mypy/Pyright/Pylint: effective dependency, configuration, script, or exact CI command.

When configuration exists without a runnable script or CI command, report the capability and the missing command separately.

## Validation Command Contract

Every Python validation result follows [validation-output.md](../../web-frontend-development/references/validation-output.md) and retains the owning project, working directory, interpreter/environment, package-manager evidence, exact command or `not configured`, category, tool evidence, result, and blocker status.

Do not report a generic command such as `pytest`, `ruff`, `black`, or `python -m build` as verified unless the repository provides the evidence for that exact invocation.
