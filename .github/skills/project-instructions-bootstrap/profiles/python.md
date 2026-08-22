# Python Profile

Activate only when the owning scope has Python project metadata or environment evidence such as `pyproject.toml`,
`setup.py`, `setup.cfg`, `requirements*.txt`, `Pipfile`, `Pipfile.lock`, `poetry.lock`, `uv.lock`, `.python-version`,
`tox.ini`, or `noxfile.py`.

Durable guidance:

- Preserve each Python project, package, and explicitly declared workspace boundary.
- Resolve the environment and package manager from project metadata and tool configuration before lockfiles, then use
  exact CI or repository tooling commands only as supporting evidence.
- Keep pip, Poetry, uv, pip-tools, Pipenv, conda, and other environment choices separate; never translate commands
  between managers or assume a preferred tool.
- Document Python version evidence from `requires-python`, `.python-version`, tool configuration, CI setup, container
  configuration, or repository configuration when it belongs to the owning scope.
- Document lint, format, type-check, test, integration, package/build, security, and performance commands only when
  declared by project metadata, dependencies, configuration, scripts, lockfiles, or CI.
- Preserve the exact command, environment/package manager, scope, working directory, and evidence source.
- Activate FastAPI, Django, Flask, Celery, pytest, Ruff, Black, Mypy, Pyright, or another framework/tool only from
  owning-project dependency, configuration, lockfile, script, or CI evidence.

Do not activate Python from `.py` files, conventional directory names, README wording, CI commands, or Dockerfiles
alone. Do not invent a default interpreter, environment, test runner, or validation command.
