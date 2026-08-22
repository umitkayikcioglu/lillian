# Python Development Validation Scenarios

Use these scenarios as the minimum routing and validation matrix for `python-development`.

| Scenario | Given | When | Then | Expected Result |
|---|---|---|---|---|
| Python package metadata | An owning `pyproject.toml` declares a Python project and `requires-python` | Discovery runs | Python development activates | Python project and validation guidance load |
| FastAPI service | A Python project declares `fastapi` and an application entry point | An API file changes | FastAPI activates from dependency evidence | Framework guidance applies without filename inference |
| Poetry project | A project has `pyproject.toml` and `poetry.lock` | Package/tool resolution runs | Poetry owns the environment evidence | Exact repository Poetry command is preserved |
| uv project | A project has `pyproject.toml` and `uv.lock` | Package/tool resolution runs | uv owns the environment evidence | Exact repository uv command is preserved |
| Python filename only | A `src/` directory contains `.py` files without project metadata | Discovery runs | Filename and directory are supporting-only | Ownership or activation remains unresolved; no command is guessed |
| Requirements project | A project has `requirements.txt` and an evidenced CI working directory | Validation resolves dependencies | Requirements evidence is retained | pip-compatible commands are not invented without script or CI evidence |
| Conflicting managers | A project has Poetry and uv lockfiles without declared precedence | Command resolution runs | Manager evidence is ambiguous | No manager-specific command is emitted |
| Tool configuration without command | Ruff, Black, or Mypy configuration exists without script or CI command | Validation resolves the tool | Capability and runnable command are separated | Result is `not configured`, not `passed` |
| Nested standalone project | A nested Python project has its own metadata and lockfile | A file changes inside it | Nested project owns the path | Parent environment evidence does not override it |
| Overlapping project roots | Two Python project roots match a file equally | Ownership resolves | The scope is ambiguous | No project or framework is selected |
| Python test routing | A project declares its test framework and test command | A test file changes | Test policy resolves from project evidence | The declared framework is used; pytest/unittest is not assumed |
