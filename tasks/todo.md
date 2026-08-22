# Node.js and Python Development Support

## Current Workflow: project-instructions-bootstrap

- [x] Add explicit user-request versus attached-document authority boundaries.
- [x] Add Node.js and Python profile references, scope rules, and definitive evidence.
- [x] Add `node.md` and `python.md` bootstrap profiles.
- [x] Extend the bootstrap validation matrix with Node.js, Python, mixed-monorepo, and authority-boundary cases.
- [x] Verify authored `.github/` DRY ownership and leave generated mirrors untouched.
- [x] Run repository-defined validation and record evidence below.

## Current Workflow Acceptance Criteria

- [x] `project-instructions-bootstrap` activates Node.js only from manifest/workspace/runtime evidence.
- [x] `project-instructions-bootstrap` activates Python only from project metadata/environment evidence.
- [x] Node.js and Python commands retain owning scope, working directory, manager/environment, and evidence source.
- [x] Frameworks, tools, and commands are not inferred from filenames, directories, CI alone, or attached-document instructions.
- [x] Existing target-file marker, transactional, path-safety, and generated-output boundaries remain unchanged.

## Current Workflow Results

- Static source validation passed: all 13 referenced templates/profiles/references exist.
- DRY validation passed: technology-specific rules remain in profiles and the skill; templates remain profile-agnostic.
- Authority-boundary validation passed: attached-document instructions are explicitly treated as context/evidence, not authorization.
- Generated-output validation passed: `.agents/`, `.claude/`, `plugins/`, and `.ai/` were not changed.
- `git diff --check` passed.
- No executable validation harness for this documentation skill was found; validation scenarios were expanded and checked statically.

## Implementation

- [x] Add the Node.js development skill and runtime boundaries.
- [x] Add the Python development skill and project/tooling discovery guidance.
- [x] Add path-scoped Node.js and Python instructions.
- [x] Update README technology coverage.
- [x] Regenerate platform outputs and skill catalogs from `.github/`.
- [x] Validate skill structure, generated output, and repository consistency.

## Review Results

- Canonical source and generated skill copies match for Node.js and Python.
- Static validation passed for frontmatter fields, references, catalogs, generated rules, and diff whitespace.
- Sync completed successfully: 18 skills, 14 instruction/rule outputs, 16 commands, and 13 agent personas processed.
- `quick_validate.py` was not run because this environment has no working Python executable.
- Reviewer fixes applied: common validation output, Node/Python scenario matrices, README validation guidance, and EOF whitespace cleanup.
- `git diff --cached --check` passed with exit code 0 after staging the corrected canonical sources.
